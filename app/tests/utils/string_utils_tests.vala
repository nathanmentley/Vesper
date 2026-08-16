/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://gnu.org>.
 */

using GLib;
using PiPod.Core.Utils;

namespace PiPod.Tests.Utils {
    void test_format_time_short () {
        string result = StringUtils.format_time(65.0);
        assert(result == "01:05");
    }

    void test_format_time_long () {
        string result = StringUtils.format_time(3665.0);
        assert(result == "01:01:05");
    }

    // This function will be called by your master test runner
    public void register_string_utils_tests () {
        Test.add_func("/pipod/utils/string_utils/format_time_short", test_format_time_short);
        Test.add_func("/pipod/utils/string_utils/format_time_long", test_format_time_long);
    }
}