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

namespace Vesper.Core.Models {
    public interface MixKind : Object {}

    public class Mix : Object {
        public MixKind kind { get; construct; }
        public string name { get; construct; }
        public string description { get; construct; }
        public string icon { get; construct; }

        public Mix (MixKind kind, string name, string description, string icon) {
            Object (kind: kind, name: name, description: description, icon: icon);
        }
    }
}
