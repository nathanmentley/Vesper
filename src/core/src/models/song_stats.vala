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
    public class SongStats : Object {
        public string song_id { get; construct; }
        public int play_count { get; construct; }
        public int64 total_play_seconds { get; construct; }
        public int64? last_played { get; private set; }

        public SongStats (
            string song_id,
            int play_count,
            int64 total_play_seconds,
            int64? last_played
        ) {
            Object (
                song_id: song_id,
                play_count: play_count,
                total_play_seconds: total_play_seconds
            );
            this.last_played = last_played;
        }
    }
}
