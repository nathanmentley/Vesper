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
    public interface LibraryRepository : Object {
        public abstract void save_library (
            string id,
            string provider_id,
            string name,
            int64 last_synced
        ) throws Error;
        
        public abstract void save_artist (
            string library_id,
            Artist artist
        ) throws Error;

        public abstract void save_album (
            string library_id,
            string artist_id,
            Album album
        ) throws Error;

        public abstract void save_song (
            string library_id,
            string artist_id,
            Song song
        ) throws Error;

        public abstract void save_genre (Genre genre) throws Error;

        public abstract Genre? get_genre (string genre_id) throws Error;

        public abstract Gee.List<Genre> get_genres () throws Error;

        public abstract void save_artist_genres (
            string artist_id,
            Gee.List<Genre> genres
        ) throws Error;

        public abstract Gee.List<Genre> get_artist_genres (
            string artist_id
        ) throws Error;

        public abstract void save_album_genres (
            string album_id,
            Gee.List<Genre> genres
        ) throws Error;

        public abstract Gee.List<Genre> get_album_genres (
            string album_id
        ) throws Error;

        public abstract void save_song_genres (
            string song_id,
            Gee.List<Genre> genres
        ) throws Error;

        public abstract Gee.List<Genre> get_song_genres (
            string song_id
        ) throws Error;

        public abstract Library? get_library (
            string library_id
        ) throws Error;

        public abstract Gee.List<Artist> get_artists (
            string library_id
        ) throws Error;

        public abstract Gee.List<Album> get_albums (
            string artist_id
        ) throws Error;

        public abstract Gee.List<Song> get_tracks (
            string album_id
        ) throws Error;

        public abstract Gee.List<Song> get_recently_added (
            int limit = 50
        ) throws Error;

        public abstract Song? get_track (
            string library_id,
            string song_id
        ) throws Error;

        public abstract Gee.List<SearchResult> search (
            string query,
            int limit = 50
        ) throws Error;
    }
}