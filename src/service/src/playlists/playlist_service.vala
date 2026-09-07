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

namespace Vesper.Service.Playlists {
    public interface PlaylistService : Object {
        public abstract async Gee.List<Playlist> get_playlists ();

        public abstract async Gee.List<Song> get_playlist_songs (string playlist_id);

        public abstract async void create_playlist (string name);

        public abstract async void update_playlist (string playlist_id, string name, Collection<Song> songs);

        public abstract async void add_song_to_playlist (string playlist_id, Song song);

        public abstract async void delete_playlist (string playlist_id);
    }
}