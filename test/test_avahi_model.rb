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

require 'test/unit'
require 'main_settings'
require 'avahi_model'

class Test::AvahiModel < Test::Unit::TestCase
    def test_pack
        array = [[102,97,99,101],[99,97,98]]
        #assert_equal("\004face\003cab", Wamupd::AvahiModel.pack_txt_param(array))
        assert_equal("\"face\" \"cab\"", Wamupd::AvahiModel.pack_txt_param(array))
    end
end
