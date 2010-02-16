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

require "main_settings"
require "dnsruby"
require "socket"
require "ipaddr"

# Manage IP information in DNS
class DNSIpController
    # Constructor
    def initialize()
        @sa = MainSettings.instance
        @sa.get_ip_addresses
        @resolver = @sa.resolver
    end

    def do_publish(target, type, ttl, value)
    end

    def do_unpublish(target, type, ttl, value)
    end

    # Publish A and AAAA records
    def publish
        if (@sa.ipv4)
            DnsUpdate.publish(@sa.target, Dnsruby::Types.A, @sa.ttl, @sa.ipv4)
        end
        if (@sa.ipv6)
            DnsUpdate.publish(@sa.target, Dnsruby::Types.AAAA, @sa.ttl, @sa.ipv6)
        end
    end

    # Unpublish A and AAAA records
    def unpublish
        if (@sa.ipv4)
            DnsUpdate.unpublish(@sa.target, Dnsruby::Types.A, @sa.ipv4)
        end
        if (@sa.ipv6)
            DnsUpdate.unpublish(@sa.target, Dnsruby::Types.AAAA, @sa.ipv6)
        end
    end
end
