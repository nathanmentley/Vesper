/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
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
using Sqlite;

namespace Vesper.Data {
    public class Migration : Object {
        private const int CURRENT_VERSION = 1;

        public static void migrate (Sqlite.Database db) throws Error {
            int version = get_version (db);

            if (version == 0) {
                migrate_v1 (db);
                return;
            }

            if (version != CURRENT_VERSION) {
                throw new IOError.FAILED (
                    "Unknown database version: %d".printf (version)
                );
            }
        }

        private static int get_version (Sqlite.Database db) throws Error {
            Sqlite.Statement statement;

            int result = db.prepare_v2 (
                "PRAGMA user_version;",
                -1,
                out statement
            );

            if (result != Sqlite.OK) {
                throw new IOError.FAILED (
                    "Failed to read database version: %s".printf (
                        db.errmsg ()
                    )
                );
            }

            result = statement.step ();

            if (result != Sqlite.ROW) {
                throw new IOError.FAILED (
                    "Failed to read database version"
                );
            }

            return statement.column_int (0);
        }

        private static void set_version (
            Sqlite.Database db,
            int version
        ) throws Error {
            exec (
                db,
                "PRAGMA user_version = %d;".printf (version)
            );
        }

        private static void migrate_v1 (
            Sqlite.Database db
        ) throws Error {
            exec (db, "BEGIN TRANSACTION;");

            try {
                exec (db, """
                    CREATE TABLE libraries (
                        id TEXT PRIMARY KEY,
                        provider_id TEXT NOT NULL,
                        name TEXT NOT NULL,
                        last_synced INTEGER NOT NULL
                    );

                    CREATE TABLE artists (
                        id TEXT PRIMARY KEY,
                        library_id TEXT NOT NULL,
                        name TEXT NOT NULL,

                        musicbrainz_artist_id TEXT,
                        added_at INTEGER,

                        FOREIGN KEY (library_id)
                            REFERENCES libraries(id)
                            ON DELETE CASCADE
                    );

                    CREATE TABLE albums (
                        id TEXT PRIMARY KEY,
                        library_id TEXT NOT NULL,
                        artist_id TEXT NOT NULL,
                        name TEXT NOT NULL,
                        year TEXT,
                        cover TEXT,

                        musicbrainz_release_id TEXT,
                        musicbrainz_release_group_id TEXT,
                        added_at INTEGER,

                        FOREIGN KEY (library_id)
                            REFERENCES libraries(id)
                            ON DELETE CASCADE,

                        FOREIGN KEY (artist_id)
                            REFERENCES artists(id)
                            ON DELETE CASCADE
                    );

                    CREATE TABLE songs (
                        id TEXT PRIMARY KEY,
                        library_id TEXT NOT NULL,
                        artist_id TEXT NOT NULL,
                        album_id TEXT NOT NULL,
                        title TEXT NOT NULL,
                        stream_url TEXT NOT NULL,
                        track_number INTEGER,

                        duration INTEGER,
                        disc_number INTEGER,
                        year INTEGER,
                        bit_rate INTEGER,
                        bit_depth INTEGER,
                        sample_rate INTEGER,
                        channel_count INTEGER,
                        file_size INTEGER,
                        content_type TEXT,
                        file_suffix TEXT,
                        bpm INTEGER,
                        musicbrainz_recording_id TEXT,
                        added_at INTEGER,

                        FOREIGN KEY (library_id)
                            REFERENCES libraries(id)
                            ON DELETE CASCADE,

                        FOREIGN KEY (artist_id)
                            REFERENCES artists(id)
                            ON DELETE CASCADE,

                        FOREIGN KEY (album_id)
                            REFERENCES albums(id)
                            ON DELETE CASCADE
                    );

                    CREATE VIRTUAL TABLE library_search USING fts5(
                        library_id UNINDEXED,
                        song_id UNINDEXED,
                        artist_id UNINDEXED,
                        album_id UNINDEXED,
                        body
                    );

                    CREATE TRIGGER song_ai
                    AFTER INSERT ON songs
                    BEGIN
                        INSERT INTO library_search(
                            library_id,
                            song_id,
                            artist_id,
                            album_id,
                            body
                        )
                        SELECT
                            new.library_id,
                            new.id,
                            new.artist_id,
                            new.album_id,
                            new.title || ' ' ||
                            artists.name || ' ' ||
                            albums.name
                        FROM artists
                        JOIN albums
                            ON albums.id = new.album_id
                        WHERE artists.id = new.artist_id;
                    END;

                    CREATE TRIGGER song_ad
                    AFTER DELETE ON songs
                    BEGIN
                        DELETE FROM library_search
                        WHERE rowid IN (
                            SELECT rowid
                            FROM library_search
                            WHERE library_id = old.library_id
                              AND song_id = old.id
                        );
                    END;

                    CREATE TRIGGER song_au
                    AFTER UPDATE ON songs
                    BEGIN
                        DELETE FROM library_search
                        WHERE rowid IN (
                            SELECT rowid
                            FROM library_search
                            WHERE library_id = old.library_id
                              AND song_id = old.id
                        );

                        INSERT INTO library_search(
                            library_id,
                            song_id,
                            artist_id,
                            album_id,
                            body
                        )
                        SELECT
                            new.library_id,
                            new.id,
                            new.artist_id,
                            new.album_id,
                            new.title || ' ' ||
                            artists.name || ' ' ||
                            albums.name
                        FROM artists
                        JOIN albums
                            ON albums.id = new.album_id
                        WHERE artists.id = new.artist_id;
                    END;

                    CREATE INDEX idx_artists_library
                    ON artists(library_id);

                    CREATE INDEX idx_albums_library
                    ON albums(library_id);

                    CREATE INDEX idx_albums_artist
                    ON albums(artist_id);

                    CREATE INDEX idx_songs_library
                    ON songs(library_id);

                    CREATE INDEX idx_songs_artist
                    ON songs(artist_id);

                    CREATE INDEX idx_songs_album
                    ON songs(album_id);

                    CREATE TABLE playlists (
                        id TEXT PRIMARY KEY,
                        name TEXT NOT NULL
                    );

                    CREATE TABLE playlist_songs (
                        id TEXT PRIMARY KEY,
                        playlist_id TEXT NOT NULL,
                        song_id TEXT NOT NULL,
                        position INTEGER NOT NULL,

                        FOREIGN KEY (playlist_id)
                            REFERENCES playlists(id)
                            ON DELETE CASCADE,

                        FOREIGN KEY (song_id)
                            REFERENCES songs(id)
                            ON DELETE CASCADE
                    );

                    CREATE INDEX idx_playlist_songs_playlist_position
                    ON playlist_songs(playlist_id, position);

                    CREATE INDEX idx_playlist_songs_song
                    ON playlist_songs(song_id);

                    CREATE TABLE artwork_cache (
                        key TEXT PRIMARY KEY,
                        data BLOB NOT NULL,
                        last_used INTEGER NOT NULL,
                        use_count INTEGER NOT NULL DEFAULT 0
                    );

                    CREATE INDEX idx_artwork_cache_last_used
                    ON artwork_cache(last_used);

                    CREATE TABLE genres (
                        id TEXT PRIMARY KEY,
                        name TEXT NOT NULL UNIQUE
                    );

                    CREATE TABLE artist_genres (
                        artist_id TEXT NOT NULL,
                        genre_id TEXT NOT NULL,

                        PRIMARY KEY (artist_id, genre_id),

                        FOREIGN KEY (artist_id)
                            REFERENCES artists(id)
                            ON DELETE CASCADE,

                        FOREIGN KEY (genre_id)
                            REFERENCES genres(id)
                            ON DELETE CASCADE
                    );

                    CREATE TABLE album_genres (
                        album_id TEXT NOT NULL,
                        genre_id TEXT NOT NULL,

                        PRIMARY KEY (album_id, genre_id),

                        FOREIGN KEY (album_id)
                            REFERENCES albums(id)
                            ON DELETE CASCADE,

                        FOREIGN KEY (genre_id)
                            REFERENCES genres(id)
                            ON DELETE CASCADE
                    );

                    CREATE TABLE song_genres (
                        song_id TEXT NOT NULL,
                        genre_id TEXT NOT NULL,

                        PRIMARY KEY (song_id, genre_id),

                        FOREIGN KEY (song_id)
                            REFERENCES songs(id)
                            ON DELETE CASCADE,

                        FOREIGN KEY (genre_id)
                            REFERENCES genres(id)
                            ON DELETE CASCADE
                    );

                    CREATE INDEX idx_artist_genres_genre
                    ON artist_genres(genre_id);

                    CREATE INDEX idx_album_genres_genre
                    ON album_genres(genre_id);

                    CREATE INDEX idx_song_genres_genre
                    ON song_genres(genre_id);

                    CREATE TABLE song_stats (
                        song_id TEXT PRIMARY KEY,
                        play_count INTEGER NOT NULL DEFAULT 0,
                        total_play_seconds INTEGER NOT NULL DEFAULT 0,
                        last_played INTEGER,

                        FOREIGN KEY (song_id)
                            REFERENCES songs(id)
                            ON DELETE CASCADE
                    );

                    CREATE TABLE play_history (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        song_id TEXT NOT NULL,
                        played_at INTEGER NOT NULL,
                        duration INTEGER NOT NULL,
                        completed INTEGER NOT NULL DEFAULT 0,

                        FOREIGN KEY (song_id)
                            REFERENCES songs(id)
                            ON DELETE CASCADE
                    );

                    CREATE INDEX idx_play_history_played_at
                    ON play_history(played_at DESC);

                    CREATE INDEX idx_play_history_song
                    ON play_history(song_id);

                    CREATE TABLE song_favorites (
                        song_id TEXT PRIMARY KEY,

                        FOREIGN KEY (song_id)
                            REFERENCES songs(id)
                            ON DELETE CASCADE
                    );
                """);

                set_version (db, 1);

                exec (db, "COMMIT;");
            } catch (Error e) {
                exec (db, "ROLLBACK;");
                throw e;
            }
        }

        private static void exec (
            Sqlite.Database db,
            string sql
        ) throws Error {
            char* error_message = null;

            int result = db.exec (
                sql,
                null,
                out error_message
            );

            if (result != Sqlite.OK) {
                string message = "SQLite error";

                if (error_message != null) {
                    message = (string) error_message;
                    Sqlite.Memory.free (error_message);
                }

                throw new IOError.FAILED (message);
            }
        }
    }
}