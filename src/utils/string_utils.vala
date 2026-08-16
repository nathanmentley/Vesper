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

namespace PiPod.Utils {
    public class StringUtils : Object {
        public const string EMPTY = "";

        private const string TIME_FORMAT_PATTERN_LONG = "%02d:%02d:%02d";
        private const string TIME_FORMAT_PATTERN_SHORT = "%02d:%02d";

        public static string format_time (double seconds) {
            int total_seconds = (int) seconds;

            int hours_segment = total_seconds / 3600;
            int minutes_segment = (total_seconds % 3600) / 60;
            int seconds_segment = total_seconds % 60;

            return hours_segment > 0 ?
                TIME_FORMAT_PATTERN_LONG.printf(hours_segment, minutes_segment, seconds_segment):
                TIME_FORMAT_PATTERN_SHORT.printf(minutes_segment, seconds_segment);
        }
    }
}