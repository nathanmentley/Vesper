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
    public class Song : Object {
        public string id { get; construct; }
        public string title { get; construct; }
        public string stream_url { get; construct; }
        public int track_number { get; construct; }
        public Album album { get; construct; }

        public Song (string id, string title, string stream_url, int track_number, Album album) {
            Object (id: id, title: title, stream_url: stream_url, track_number: track_number, album: album);
        }
    }
}