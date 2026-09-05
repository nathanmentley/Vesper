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
using Gee;
using Sqlite;

using Vesper.Core.Models;

namespace Vesper.Data {
    public class LibraryRepository : Object {
        private Database database;

        public LibraryRepository (Database database) {
            this.database = database;
        }

        public void save_library (
            string id,
            string provider_id,
            string name,
            int64 last_synced
        ) throws Error {
            var statement = prepare ("""
                INSERT INTO libraries (
                    id,
                    provider_id,
                    name,
                    last_synced
                )
                VALUES (?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    provider_id = excluded.provider_id,
                    name = excluded.name,
                    last_synced = excluded.last_synced;
            """);

            statement.bind_text (1, id);
            statement.bind_text (2, provider_id);
            statement.bind_text (3, name);
            statement.bind_int64 (4, last_synced);

            step_done (statement);
        }

        public void save_artist (
            string library_id,
            Artist artist
        ) throws Error {
            var statement = prepare ("""
                INSERT INTO artists (
                    id,
                    library_id,
                    name
                )
                VALUES (?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    library_id = excluded.library_id,
                    name = excluded.name;
            """);

            statement.bind_text (1, artist.id);
            statement.bind_text (2, library_id);
            statement.bind_text (3, artist.name);

            step_done (statement);
        }

        public void save_album (
            string library_id,
            string artist_id,
            Album album
        ) throws Error {
            var statement = prepare ("""
                INSERT INTO albums (
                    id,
                    library_id,
                    artist_id,
                    name,
                    year,
                    cover
                )
                VALUES (?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    library_id = excluded.library_id,
                    artist_id = excluded.artist_id,
                    name = excluded.name,
                    year = excluded.year,
                    cover = excluded.cover;
            """);

            statement.bind_text (1, album.id);
            statement.bind_text (2, library_id);
            statement.bind_text (3, artist_id);
            statement.bind_text (4, album.name);

            if (album.year != null) {
                statement.bind_text (5, album.year);
            } else {
                statement.bind_null (5);
            }

            if (album.cover != null) {
                statement.bind_text (6, album.cover);
            } else {
                statement.bind_null (6);
            }

            step_done (statement);
        }

        public void save_song (
            string library_id,
            string artist_id,
            Song song
        ) throws Error {
            var statement = prepare ("""
                INSERT INTO songs (
                    id,
                    library_id,
                    artist_id,
                    album_id,
                    title,
                    stream_url,
                    track_number
                )
                VALUES (?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    library_id = excluded.library_id,
                    artist_id = excluded.artist_id,
                    album_id = excluded.album_id,
                    title = excluded.title,
                    stream_url = excluded.stream_url,
                    track_number = excluded.track_number;
            """);

            statement.bind_text (1, song.id);
            statement.bind_text (2, library_id);
            statement.bind_text (3, artist_id);
            statement.bind_text (4, song.album.id);
            statement.bind_text (5, song.title);
            statement.bind_text (6, song.stream_url);
            statement.bind_int (7, song.track_number);

            step_done (statement);
        }

        public Library? get_library (
            string library_id
        ) throws Error {
            var statement = prepare ("""
                SELECT
                    id,
                    provider_id,
                    name,
                    last_synced
                FROM libraries
                WHERE id = ?;
            """);

            statement.bind_text (1, library_id);

            if (statement.step () != Sqlite.ROW) {
                return null;
            }

            return new Library (
                statement.column_text (0),
                statement.column_text (1),
                statement.column_text (2),
                statement.column_int64 (3)
            );
        }

        public Gee.List<Artist> get_artists (
            string library_id
        ) throws Error {
            var artists = new Gee.ArrayList<Artist> ();

            var statement = prepare ("""
                SELECT
                    id,
                    name,
                    library_id
                FROM artists
                WHERE library_id = ?
                ORDER BY name;
            """);

            statement.bind_text (1, library_id);

            while (statement.step () == Sqlite.ROW) {
                artists.add (
                    new Artist (
                        statement.column_text (0),
                        statement.column_text (1),
                        statement.column_text (2)
                    )
                );
            }

            return artists;
        }

        public Gee.List<Album> get_albums (
            string artist_id
        ) throws Error {
            var albums = new Gee.ArrayList<Album> ();

            var statement = prepare ("""
                SELECT
                    id,
                    name,
                    cover,
                    year
                FROM albums
                WHERE artist_id = ?
                ORDER BY year ASC, name ASC;
            """);

            statement.bind_text (1, artist_id);

            while (statement.step () == Sqlite.ROW) {
                string? cover = null;
                string? year = null;

                if (statement.column_type (2) != Sqlite.NULL) {
                    cover = statement.column_text (2);
                }

                if (statement.column_type (3) != Sqlite.NULL) {
                    year = statement.column_text (3);
                }

                albums.add (
                    new Album (
                        statement.column_text (0),
                        statement.column_text (1),
                        cover,
                        year
                    )
                );
            }

            return albums;
        }

        public Gee.List<Song> get_tracks (
            string album_id
        ) throws Error {
            var songs = new Gee.ArrayList<Song> ();

            var album_statement = prepare ("""
                SELECT
                    id,
                    name,
                    cover,
                    year
                FROM albums
                WHERE id = ?
            """);

            album_statement.bind_text (1, album_id);

            if (album_statement.step () != Sqlite.ROW) {
                return songs;
            }

            string? cover = null;
            string? year = null;

            if (album_statement.column_type (2) != Sqlite.NULL) {
                cover = album_statement.column_text (2);
            }

            if (album_statement.column_type (3) != Sqlite.NULL) {
                year = album_statement.column_text (3);
            }

            var album = new Album (
                album_statement.column_text (0),
                album_statement.column_text (1),
                cover,
                year
            );

            var statement = prepare ("""
                SELECT
                    id,
                    title,
                    stream_url,
                    track_number
                FROM songs
                WHERE album_id = ?
                ORDER BY track_number ASC, title ASC;
            """);

            statement.bind_text (1, album_id);

            while (statement.step () == Sqlite.ROW) {
                songs.add (
                    new Song (
                        statement.column_text (0),
                        statement.column_text (1),
                        statement.column_text (2),
                        statement.column_int (3),
                        album
                    )
                );
            }

            return songs;
        }

        public Song? get_track (
            string library_id,
            string song_id
        ) throws Error {
            var statement = prepare ("""
                SELECT
                    s.id,
                    s.title,
                    s.stream_url,
                    a.id,
                    a.name,
                    a.cover,
                    a.year,
                    s.track_number
                FROM songs s
                JOIN albums a ON s.album_id = a.id
                WHERE s.id = ?;
            """);

            statement.bind_text (1, song_id);

            if (statement.step () != Sqlite.ROW) {
                return null;
            }

            string? cover = null;
            string? year = null;

            if (statement.column_type (5) != Sqlite.NULL) {
                cover = statement.column_text (5);
            }

            if (statement.column_type (6) != Sqlite.NULL) {
                year = statement.column_text (6);
            }

            var album = new Album (
                statement.column_text (3),
                statement.column_text (4),
                cover,
                year
            );

            return new Song (
                statement.column_text (0),
                statement.column_text (1),
                statement.column_text (2),
                statement.column_int (8),
                album
            );
        }

        private Sqlite.Statement prepare (
            string sql
        ) throws Error {
            Sqlite.Statement statement;

            int result = database.connection.prepare_v2 (
                sql,
                -1,
                out statement
            );

            if (result != Sqlite.OK) {
                throw new IOError.FAILED (
                    "Failed to prepare SQL statement: %s".printf (
                        database.connection.errmsg ()
                    )
                );
            }

            return statement;
        }

        private void step_done (
            Sqlite.Statement statement
        ) throws Error {
            int result = statement.step ();

            if (result != Sqlite.DONE) {
                throw new IOError.FAILED (
                    "SQLite statement failed: %s".printf (
                        database.connection.errmsg ()
                    )
                );
            }
        }
    }
}