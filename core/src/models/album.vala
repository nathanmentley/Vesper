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

namespace PiPod.Core.Models {
    public class Album : Object {
        public string id { get; construct; }
        public string name { get; construct; }
        public string? cover { get; construct; }
        public string? year { get; construct; }

        public Album (string id, string name, string? cover = null,string? year = null) {
            Object (id: id, name: name, cover: cover, year: year);
        }

        public string display_name () {
            if (year != null) {
                return "%s (%s)".printf (name, year);
            }

            return name;
        }
    }
}