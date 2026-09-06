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

using Vesper.Core.Models;

namespace Vesper.Data {
    public interface PlaylistRepository : Object {
        public abstract void save_playlist (
            Playlist playlist
        ) throws Error;

        public abstract void delete_playlist (
            string playlist_id
        ) throws Error;

        public abstract Playlist? get_playlist (
            string playlist_id
        ) throws Error;

        public abstract Gee.List<Playlist> get_playlists () throws Error;

        public abstract PlaylistItem? get_item (
            string item_id
        ) throws Error;

        public abstract Gee.List<PlaylistItem> get_items (
            string playlist_id
        ) throws Error;

        public abstract void add_item (
            PlaylistItem item
        ) throws Error;

        public abstract void remove_item (
            string item_id
        ) throws Error;

        public abstract void clear_items (
            string playlist_id
        ) throws Error;

        public abstract void reorder_item (
            string item_id,
            int new_position
        ) throws Error;
    }
}