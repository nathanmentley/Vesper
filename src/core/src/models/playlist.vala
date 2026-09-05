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

using Gee;
using GLib;

namespace Vesper.Core.Models {
    public class Playlist : Object {
        public string id { get; construct; }
        public string name { get; construct; }
        public int song_count { get; construct; }
        public int duration { get; construct; }
        public string? cover_art { get; construct; }

        public Playlist (
            string id,
            string name,
            int song_count,
            int duration,
            string? cover_art
        ) {
            Object (
                id: id,
                name: name,
                song_count: song_count,
                duration: duration,
                cover_art: cover_art
            );
        }
    }
}