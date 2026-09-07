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
    public sealed class LibraryRepositoryImpl : LibraryRepository, Object {
        private Database database;

        public LibraryRepositoryImpl (Database database) {
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
                    name,
                    musicbrainz_artist_id
                )
                VALUES (?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    library_id = excluded.library_id,
                    name = excluded.name,
                    musicbrainz_artist_id = excluded.musicbrainz_artist_id;
            """);

            statement.bind_text (1, artist.id);
            statement.bind_text (2, library_id);
            statement.bind_text (3, artist.name);
            bind_text (statement, 4, artist.musicbrainz_artist_id);

            step_done (statement);
            save_artist_genres (artist.id, artist.genres);
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
                    cover,
                    musicbrainz_release_id,
                    musicbrainz_release_group_id
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    library_id = excluded.library_id,
                    artist_id = excluded.artist_id,
                    name = excluded.name,
                    year = excluded.year,
                    cover = excluded.cover,
                    musicbrainz_release_id = excluded.musicbrainz_release_id,
                    musicbrainz_release_group_id = excluded.musicbrainz_release_group_id;
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

            bind_text (statement, 7, album.musicbrainz_release_id);
            bind_text (statement, 8, album.musicbrainz_release_group_id);

            step_done (statement);
            save_album_genres (album.id, album.genres);
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
                    track_number,
                    duration,
                    disc_number,
                    year,
                    bit_rate,
                    bit_depth,
                    sample_rate,
                    channel_count,
                    file_size,
                    content_type,
                    file_suffix,
                    bpm,
                    musicbrainz_recording_id
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    library_id = excluded.library_id,
                    artist_id = excluded.artist_id,
                    album_id = excluded.album_id,
                    title = excluded.title,
                    stream_url = excluded.stream_url,
                    track_number = excluded.track_number,
                    duration = excluded.duration,
                    disc_number = excluded.disc_number,
                    year = excluded.year,
                    bit_rate = excluded.bit_rate,
                    bit_depth = excluded.bit_depth,
                    sample_rate = excluded.sample_rate,
                    channel_count = excluded.channel_count,
                    file_size = excluded.file_size,
                    content_type = excluded.content_type,
                    file_suffix = excluded.file_suffix,
                    bpm = excluded.bpm,
                    musicbrainz_recording_id = excluded.musicbrainz_recording_id;
            """);

            statement.bind_text (1, song.id);
            statement.bind_text (2, library_id);
            statement.bind_text (3, artist_id);
            statement.bind_text (4, song.album.id);
            statement.bind_text (5, song.title);
            statement.bind_text (6, song.stream_url);
            statement.bind_int (7, song.track_number);

            bind_int (statement, 8, song.duration);
            bind_int (statement, 9, song.disc_number);
            bind_int (statement, 10, song.year);
            bind_int (statement, 11, song.bit_rate);
            bind_int (statement, 12, song.bit_depth);
            bind_int (statement, 13, song.sample_rate);
            bind_int (statement, 14, song.channel_count);
            bind_int64 (statement, 15, song.file_size);
            bind_text (statement, 16, song.content_type);
            bind_text (statement, 17, song.file_suffix);
            bind_int (statement, 18, song.bpm);
            bind_text (statement, 19, song.musicbrainz_recording_id);

            step_done (statement);
            save_song_genres (song.id, song.genres);
        }

        public void save_genre (Genre genre) throws Error {
            var statement = prepare ("""
                INSERT OR IGNORE INTO genres (id, name) VALUES (?, ?);
            """);
            statement.bind_text (1, genre.id);
            statement.bind_text (2, genre.name);
            step_done (statement);
        }

        public Genre? get_genre (string genre_id) throws Error {
            var statement = prepare ("SELECT id, name FROM genres WHERE id = ?;");
            statement.bind_text (1, genre_id);
            if (statement.step () != Sqlite.ROW) {
                return null;
            }
            return new Genre.with_id (
                statement.column_text (0),
                statement.column_text (1)
            );
        }

        public Gee.List<Genre> get_genres () throws Error {
            return get_genres_from ("SELECT id, name FROM genres ORDER BY name;");
        }

        public void save_artist_genres (string artist_id, Gee.List<Genre> genres) throws Error {
            save_entity_genres ("artist_genres", "artist_id", artist_id, genres);
        }

        public Gee.List<Genre> get_artist_genres (string artist_id) throws Error {
            return get_entity_genres ("artist_genres", "artist_id", artist_id);
        }

        public void save_album_genres (string album_id, Gee.List<Genre> genres) throws Error {
            save_entity_genres ("album_genres", "album_id", album_id, genres);
        }

        public Gee.List<Genre> get_album_genres (string album_id) throws Error {
            return get_entity_genres ("album_genres", "album_id", album_id);
        }

        public void save_song_genres (string song_id, Gee.List<Genre> genres) throws Error {
            save_entity_genres ("song_genres", "song_id", song_id, genres);
        }

        public Gee.List<Genre> get_song_genres (string song_id) throws Error {
            return get_entity_genres ("song_genres", "song_id", song_id);
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
                    library_id,
                    musicbrainz_artist_id
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
                        statement.column_text (2),
                        get_artist_genres (statement.column_text (0)),
                        nullable_text (statement, 3)
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
                    year,
                    musicbrainz_release_id,
                    musicbrainz_release_group_id
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
                        year,
                        get_album_genres (statement.column_text (0)),
                        nullable_text (statement, 4),
                        nullable_text (statement, 5)
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
                    year,
                    musicbrainz_release_id,
                    musicbrainz_release_group_id
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
                year,
                get_album_genres (album_statement.column_text (0)),
                nullable_text (album_statement, 4),
                nullable_text (album_statement, 5)
            );

            var statement = prepare ("""
                SELECT
                    id,
                    title,
                    stream_url,
                    track_number,
                    duration,
                    disc_number,
                    year,
                    bit_rate,
                    bit_depth,
                    sample_rate,
                    channel_count,
                    file_size,
                    content_type,
                    file_suffix,
                    bpm,
                    musicbrainz_recording_id
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
                        album,
                        nullable_int (statement, 4),
                        nullable_int (statement, 5),
                        nullable_int (statement, 6),
                        nullable_int (statement, 7),
                        nullable_int (statement, 8),
                        nullable_int (statement, 9),
                        nullable_int (statement, 10),
                        nullable_int (statement, 11),
                        nullable_text (statement, 12),
                        nullable_text (statement, 13),
                        nullable_int (statement, 14),
                        nullable_text (statement, 15),
                        get_song_genres (statement.column_text (0))
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
                    s.track_number,
                    s.duration,
                    s.disc_number,
                    s.year,
                    s.bit_rate,
                    s.bit_depth,
                    s.sample_rate,
                    s.channel_count,
                    s.file_size,
                    s.content_type,
                    s.file_suffix,
                    s.bpm,
                    s.musicbrainz_recording_id,
                    a.musicbrainz_release_id,
                    a.musicbrainz_release_group_id
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
                year,
                get_album_genres (statement.column_text (3)),
                nullable_text (statement, 20),
                nullable_text (statement, 21)
            );

            return new Song (
                statement.column_text (0),
                statement.column_text (1),
                statement.column_text (2),
                statement.column_int (7),
                album,
                nullable_int (statement, 8),
                nullable_int (statement, 9),
                nullable_int (statement, 10),
                nullable_int (statement, 11),
                nullable_int (statement, 12),
                nullable_int (statement, 13),
                nullable_int (statement, 14),
                nullable_int (statement, 15),
                nullable_text (statement, 16),
                nullable_text (statement, 17),
                nullable_int (statement, 18),
                nullable_text (statement, 19),
                get_song_genres (statement.column_text (0))
            );
        }

        public Gee.List<SearchResult> search (
            string query,
            int limit = 50
        ) throws Error {
            var results = new Gee.ArrayList<SearchResult> ();
        
            if (query.strip ().length == 0) {
                return results;
            }
        
            var statement = prepare ("""
                SELECT
                    ls.library_id,
                    ls.song_id,
                    s.title,
                    s.stream_url,
                    s.track_number,
        
                    a.id,
                    a.name,
                    a.cover,
                    a.year,
        
                    ar.id,
                    ar.name,
        
                    bm25(library_search) AS rank
                FROM library_search ls
                JOIN songs s
                    ON s.id = ls.song_id
                    AND s.library_id = ls.library_id
                JOIN albums a
                    ON a.id = s.album_id
                    AND a.library_id = s.library_id
                JOIN artists ar
                    ON ar.id = s.artist_id
                    AND ar.library_id = s.library_id
                WHERE library_search MATCH ?
                ORDER BY rank
                LIMIT ?;
            """);
        
            statement.bind_text (1, query);
            statement.bind_int (2, limit);
        
            while (statement.step () == Sqlite.ROW) {
                string? cover = null;
                string? year = null;
        
                if (statement.column_type (7) != Sqlite.NULL) {
                    cover = statement.column_text (7);
                }
        
                if (statement.column_type (8) != Sqlite.NULL) {
                    year = statement.column_text (8);
                }
        
                var album = new Album (
                    statement.column_text (5),
                    statement.column_text (6),
                    cover,
                    year
                );
        
                var song = new Song (
                    statement.column_text (1),
                    statement.column_text (2),
                    statement.column_text (3),
                    statement.column_int (4),
                    album
                );
        
                var artist = new Artist (
                    statement.column_text (9),
                    statement.column_text (10),
                    statement.column_text (0)
                );
        
                results.add (
                    new SearchResult (
                        statement.column_text (0),
                        song,
                        artist,
                        statement.column_double (11)
                    )
                );
            }
        
            return results;
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

        private void bind_int (
            Sqlite.Statement statement,
            int index,
            int? value
        ) {
            if (value != null) {
                statement.bind_int (index, value);
            } else {
                statement.bind_null (index);
            }
        }

            private int? nullable_int (Sqlite.Statement statement, int index) {
                if (statement.column_type (index) == Sqlite.NULL) {
                    return null;
                }
                return statement.column_int (index);
            }

            private string? nullable_text (Sqlite.Statement statement, int index) {
                if (statement.column_type (index) == Sqlite.NULL) {
                    return null;
                }
                return statement.column_text (index);
            }
        private void bind_int64 (
            Sqlite.Statement statement,
            int index,
            int64? value
        ) {
            if (value != null) {
                statement.bind_int64 (index, value);
            } else {
                statement.bind_null (index);
            }
        }

        private void bind_text (
            Sqlite.Statement statement,
            int index,
            string? value
        ) {
            if (value != null) {
                statement.bind_text (index, value);
            } else {
                statement.bind_null (index);
            }
        }

        private Gee.List<Genre> get_genres_from (string sql) throws Error {
            var genres = new Gee.ArrayList<Genre> ();
            var statement = prepare (sql);
            while (statement.step () == Sqlite.ROW) {
                genres.add (new Genre.with_id (
                    statement.column_text (0),
                    statement.column_text (1)
                ));
            }
            return genres;
        }

        private void save_entity_genres (
            string table,
            string entity_column,
            string entity_id,
            Gee.List<Genre> genres
        ) throws Error {
            var delete_statement = prepare (
                "DELETE FROM %s WHERE %s = ?;".printf (table, entity_column)
            );
            delete_statement.bind_text (1, entity_id);
            step_done (delete_statement);

            foreach (Genre genre in genres) {
                save_genre (genre);
                var link_statement = prepare (
                    "INSERT OR IGNORE INTO %s (%s, genre_id) VALUES (?, ?);".printf (
                        table,
                        entity_column
                    )
                );
                link_statement.bind_text (1, entity_id);
                link_statement.bind_text (2, genre.id);
                step_done (link_statement);
            }
        }

        private Gee.List<Genre> get_entity_genres (
            string table,
            string entity_column,
            string entity_id
        ) throws Error {
            var statement = prepare ("""
                SELECT g.id, g.name
                FROM genres g
                JOIN %s eg ON eg.genre_id = g.id
                WHERE eg.%s = ?
                ORDER BY g.name;
            """.printf (table, entity_column));
            statement.bind_text (1, entity_id);
            var genres = new Gee.ArrayList<Genre> ();
            while (statement.step () == Sqlite.ROW) {
                genres.add (new Genre.with_id (
                    statement.column_text (0),
                    statement.column_text (1)
                ));
            }
            return genres;
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