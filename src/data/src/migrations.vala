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
using Sqlite;

namespace Vesper.Data {
    public class Migration : Object {
        private const int CURRENT_VERSION = 2;

        public static void migrate (Sqlite.Database db) throws Error {
            int version = get_version (db);

            while (version < CURRENT_VERSION) {
                switch (version) {
                    case 0:
                        migrate_v1 (db);
                        migrate_v2 (db);
                        version = 2;
                        break;

                    case 1:
                        migrate_v2 (db);
                        version = 2;
                        break;

                    default:
                        throw new IOError.FAILED (
                            "Unknown database version: %d".printf (version)
                        );
                }
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

        private static void migrate_v1 (Sqlite.Database db) throws Error {
            exec (db, "BEGIN TRANSACTION;");

            try {
                exec (db, """
                    CREATE TABLE libraries (
                        id TEXT PRIMARY KEY,
                        provider_id TEXT NOT NULL,
                        name TEXT NOT NULL,
                        last_synced INTEGER NOT NULL
                    );
                """);

                exec (db, """
                    CREATE TABLE artists (
                        id TEXT PRIMARY KEY,
                        library_id TEXT NOT NULL,
                        name TEXT NOT NULL,

                        FOREIGN KEY (library_id)
                            REFERENCES libraries(id)
                            ON DELETE CASCADE
                    );
                """);

                exec (db, """
                    CREATE TABLE albums (
                        id TEXT PRIMARY KEY,
                        library_id TEXT NOT NULL,
                        artist_id TEXT NOT NULL,
                        name TEXT NOT NULL,
                        year TEXT,
                        cover TEXT,

                        FOREIGN KEY (library_id)
                            REFERENCES libraries(id)
                            ON DELETE CASCADE,

                        FOREIGN KEY (artist_id)
                            REFERENCES artists(id)
                            ON DELETE CASCADE
                    );
                """);

                exec (db, """
                    CREATE TABLE songs (
                        id TEXT PRIMARY KEY,
                        library_id TEXT NOT NULL,
                        artist_id TEXT NOT NULL,
                        album_id TEXT NOT NULL,
                        title TEXT NOT NULL,
                        stream_url TEXT NOT NULL,
                        track_number INTEGER,

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
                """);

                exec (db, """
                    CREATE INDEX idx_artists_library
                    ON artists(library_id);
                """);

                exec (db, """
                    CREATE INDEX idx_albums_library
                    ON albums(library_id);
                """);

                exec (db, """
                    CREATE INDEX idx_albums_artist
                    ON albums(artist_id);
                """);

                exec (db, """
                    CREATE INDEX idx_songs_library
                    ON songs(library_id);
                """);

                exec (db, """
                    CREATE INDEX idx_songs_artist
                    ON songs(artist_id);
                """);

                exec (db, """
                    CREATE INDEX idx_songs_album
                    ON songs(album_id);
                """);

                set_version (db, 1);

                exec (db, "COMMIT;");
            } catch (Error e) {
                exec (db, "ROLLBACK;");
                throw e;
            }
        }

        private static void migrate_v2 (
            Sqlite.Database db
        ) throws Error {
            exec (db, "BEGIN TRANSACTION;");

            try {
                exec (db, """
                    CREATE TABLE playlists (
                        id TEXT PRIMARY KEY,
                        name TEXT NOT NULL
                    );
                """);

                exec (db, """
                    CREATE TABLE playlist_songs (
                        id TEXT PRIMARY KEY,
                        playlist_id TEXT NOT NULL,
                        song_id TEXT NOT NULL,
                        position INTEGER NOT NULL,

                        FOREIGN KEY (playlist_id)
                            REFERENCES playlists(id)
                            ON DELETE CASCADE
                    );
                """);

                exec (db, """
                    CREATE INDEX idx_playlist_songs_playlist_position
                    ON playlist_songs(playlist_id, position);
                """);

                exec (db, """
                    CREATE INDEX idx_playlist_songs_song
                    ON playlist_songs(song_id);
                """);

                set_version (db, 2);

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