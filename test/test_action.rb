# Copyright (C) 2010 James Brown <roguelazer@roguelazer.com>.
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

require "action"

class TestAction < Test::Unit::TestCase
    def test_basic
        assert_not_nil(Wamupd::ActionType::ADD)
        assert_not_nil(Wamupd::ActionType::DELETE)
        assert_nothing_raised {
            a = Wamupd::Action.new(Wamupd::ActionType::ADD, "")
        }
    end
end
