#!/usr/bin/ruby
# Copyright (C) 2009-2010 James Brown <roguelazer@roguelazer.com>.
#
# This file is part of wamupd.
#
# wamupd is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# wamupd is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with wamupd.  If not, see <http://www.gnu.org/licenses/>.
#
# == Synopsis
# 
# wamupd: Read avahi service descriptions and current IP information, then
# use that information to generate Wide-Area mDNS Updates
#
# == Usage
#
# wamupd service-file
#
# -A DIRECTORY, --avahi-services DIRECTORY
#   Load Avahi service definitions from DIRECTORY
#   If DIRECTORY is not provided, defaults to /etc/avahi/services
# -c FILE, --config FILE:
#   Get configuration data from FILE
# -i, --ip-addreses (or --no-ip-addresses)
#   Enable/Disable Publishing A and AAAA records
# -h, --help:
#   Show this help
# -p, --publish
#   Publish records
# -u, --unpublish
#   Unpublish records

# Update the include path
$:.push(File.dirname(__FILE__))

require "avahi_model"
require "avahi_service"
require "avahi_service_file"
require "dns_avahi_controller"
require "dns_ip_controller"

require "getoptlong"
require "rdoc/usage"
require "singleton"
require "timeout"

# Wamupd is a module that is used to namespace all of the wamupd code.
module Wamupd

    OPTS = GetoptLong.new(
        ["--help", "-h", GetoptLong::NO_ARGUMENT],
        ["--config", "-c", GetoptLong::REQUIRED_ARGUMENT],
        ["--publish", "-p", GetoptLong::NO_ARGUMENT],
        ["--unpublish", "-u", GetoptLong::NO_ARGUMENT],
        ["--avahi-services", "-A", GetoptLong::OPTIONAL_ARGUMENT],
        ["--ip-addresses", "-i", GetoptLong::NO_ARGUMENT],
        ["--no-ip-addresses", GetoptLong::NO_ARGUMENT]
    )

    DEFAULT_CONFIG_FILE = "/etc/wamupd.yaml"
    DEFAULT_AVAHI_DIR   = "/etc/avahi/services/"

    # Main wamupd object
    class Main
        include Singleton

        # Process command-line objects
        def process_args
            @config_file = DEFAULT_CONFIG_FILE
            @avahi_dir = DEFAULT_AVAHI_DIR

            boolean_vars = {
                "--publish" => :publish,
                "--unpublish" => :unpublish,
                "--avahi-services" => :avahi,
                "--ip-addresses" => :ip
            }

            OPTS.each do |opt,arg|
                case opt
                when "--help"
                    RDoc::usage
                when "--config"
                    @config_file = arg.to_s
                when "--avahi-services"
                    if (not arg.nil? and arg != "")
                        @avahi_dir=arg
                    end
                when "--no-ip-addresses"
                    @bools[:ip] = false
                end
                if (boolean_vars.has_key?(opt))
                    @bools[boolean_vars[opt]] = true
                end
            end
        end

        # Construct the object and process all command-line options
        def initialize
            @bools = {
                :publish=>false,
                :unpublish=>false,
                :avahi=>false,
                :ip=>false
            }

            $settings = MainSettings.instance()

            process_args()

            # Load settings
            if (not File.exists?(@config_file))
                $stderr.puts "Could not find configuration file #{@config_file}"
                $stderr.puts "Try running with --help?"
                exit
            end
            $settings.load_from_yaml(@config_file)

            if (not (@bools[:avahi] or @bools[:ip]))
                $stderr.puts "No action specified!"
                $stderr.puts "Try running with --help (or adding a -i or -A)"
                exit
            end

            if (@bools[:ip])
                @d = DNSIpController.new()
            end

            if (@bools[:avahi])
                @avahi_services = AvahiServiceFile.load_from_directory(@avahi_dir)
                @a = Wamupd::DNSAvahiController.new()

                @am = Wamupd::AvahiModel.new
            end
        end

        # Actually run the program
        def run
            publish_static

            update_queue = Queue.new
            DNSUpdate.queue = update_queue

            threads = []
            if (@bools[:avahi])
                # Handle the DNS controller
                threads << Thread.new {
                    @a.on(:quit) {
                        Thread.exit
                    }
                    @a.on(:added) { |item|
                        puts "Added #{item.type_in_zone_with_name}"
                    }
                    @a.on(:deleted) { |item|
                        puts "Deleted #{item.type_in_zone_with_name}"
                    }
                    @a.run
                }

                # Lease maintenance
                threads << Thread.new {
                    @a.update_leases
                }

                threads << Thread.new{
                    @d.update_leases
                }

                @am.on(:added) { |avahi_service|
                    @a.queue << Wamupd::Action.new(Wamupd::ActionType::ADD, avahi_service)
                }
                # Handle listening to D-BUS
                threads << Thread.new {
                    @am.run
                }
            end

            trap("USR1") {
                puts "Unregistering services, please wait..."
                if (@bools[:avahi])
                    @am.exit
                    @a.exit
                end
                if (@bools[:ip])
                    @d.unpublish
                end
                Thread.new {
                    while (DNSUpdate.outstanding.count > 0)
                        puts "Outstanding count: #{DNSUpdate.outstanding.count}"
                        response_id, response, exception = update_queue.pop
                        puts "Got response on #{response_id}"
                        if (not exception.nil?)
                            puts response
                            puts exception
                        end
                        if DNSUpdate.outstanding.delete(response_id).nil?
                            $stderr.puts "Got back an unexpected response"
                            $stderr.puts response
                        end
                    end
                }
                sleep($settings.max_dns_response_time)
                threads.each { |t|
                    t.exit
                }
            }

            threads.each { |t|
                t.join
            }
        end

        def publish_static
            if (@d)
                @d.publish
            end

            if (@a)
                @avahi_services.each { |avahi_service_file|
                    avahi_service_file.each { |avahi_service|
                        @a.queue << Wamupd::Action.new(Wamupd::ActionType::ADD, avahi_service)
                    }
                }
            end
        end
        
        def unpublish_static
            if (@d)
                @d.unpublish
            end

            if (@a)
                @a.unpublish_all
            end
        end

        private :process_args
    end
end


if (__FILE__ == $0)
    w = Wamupd::Main.instance
    w.run
end
