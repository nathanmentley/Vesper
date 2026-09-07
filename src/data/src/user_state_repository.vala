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
using Vesper.Core.Models;

namespace Vesper.Data {
    public interface UserStateRepository : Object {
        public abstract SongStats? get (string song_id) throws Error;

        public abstract void record_play (
            string song_id,
            int64 played_at,
            int duration,
            bool completed
        ) throws Error;

        public abstract void append (PlayHistoryEntry entry) throws Error;

        public abstract Gee.List<PlayHistoryEntry> get_recent (
            int limit = 50
        ) throws Error;

        public abstract Gee.List<string> get_recent_song_ids (
            int limit = 50
        ) throws Error;

        public abstract Gee.List<string> get_most_played_song_ids (
            int limit = 50
        ) throws Error;

        public abstract Gee.List<string> get_never_played_song_ids (
            int limit = 50
        ) throws Error;

        public abstract void cleanup (
            int64 retention_seconds = 90 * 24 * 60 * 60,
            int maximum_events = 1000
        ) throws Error;

        public abstract bool is_favorite (string song_id) throws Error;

        public abstract void add_favorite (string song_id) throws Error;

        public abstract void remove_favorite (string song_id) throws Error;

        public abstract Gee.List<string> get_favorite_song_ids () throws Error;
    }
}
