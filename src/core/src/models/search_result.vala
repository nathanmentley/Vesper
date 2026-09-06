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
    public sealed class SearchResult : Object {
        public string library_id { get; construct; }
        public Song song { get; construct; }
        public Artist artist { get; construct; }
        public double rank { get; construct; }

        public SearchResult (
            string library_id,
            Song song,
            Artist artist,
            double rank
        ) {
            Object (
                library_id: library_id,
                song: song,
                artist: artist,
                rank: rank
            );
        }
    }
}