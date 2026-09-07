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

namespace Vesper.Service.UserState {
    public interface UserStateService : Object {
        public abstract void record_play (
            string song_id,
            int64 played_at,
            int duration,
            bool completed
        ) throws Error;

        public abstract SongStats? get_song_stats (string song_id) throws Error;

        public abstract Gee.List<PlayHistoryEntry> get_recently_played (
            int limit = 50
        ) throws Error;

        public abstract void cleanup_play_history (
            int64 retention_seconds = 90 * 24 * 60 * 60,
            int maximum_events = 1000
        ) throws Error;

        public abstract bool is_favorite (string song_id) throws Error;

        public abstract void favorite (string song_id) throws Error;

        public abstract void unfavorite (string song_id) throws Error;

        public abstract async Gee.List<Song> get_favorites () throws Error;

        public abstract async Gee.List<Song> get_recently_played_songs (int limit = 50) throws Error;

        public abstract async Gee.List<Song> get_most_played (int limit = 50) throws Error;

        public abstract async Gee.List<Song> get_never_played (int limit = 50) throws Error;
    }
}
