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
    public sealed class ArtworkCacheRepositoryImpl
        : ArtworkCacheRepository, Object {

        private Database database;

        public ArtworkCacheRepositoryImpl (Database database) {
            this.database = database;
        }

        public new Bytes? get (
            string key
        ) throws Error {
            var statement = prepare ("""
                SELECT
                    data
                FROM artwork_cache
                WHERE key = ?;
            """);

            statement.bind_text (1, key);

            if (statement.step () != Sqlite.ROW) {
                return null;
            }

            int size = statement.column_bytes (0);

            if (size == 0) {
                touch (key);

                return new Bytes (new uint8[0]);
            }

            void* blob = statement.column_blob (0);

            uint8[] data = (uint8[]) blob;

            var result = new Bytes (data[0:size]);

            touch (key);

            return result;
        }

        public void save (
            string key,
            Bytes data
        ) throws Error {
            var statement = prepare ("""
                INSERT INTO artwork_cache (
                    key,
                    data,
                    last_used,
                    use_count
                )
                VALUES (?, ?, ?, 1)
                ON CONFLICT(key) DO UPDATE SET
                    data = excluded.data,
                    last_used = excluded.last_used,
                    use_count = artwork_cache.use_count + 1;
            """);

            statement.bind_text (1, key);

            unowned uint8[] raw_data = data.get_data ();

            statement.bind_blob (
                2,
                raw_data,
                raw_data.length
            );

            statement.bind_int64 (
                3,
                new DateTime.now_utc ().to_unix ()
            );

            step_done (statement);
        }

        public void evict (
            int64 max_age,
            int64 max_size
        ) throws Error {
            int64 now = new DateTime.now_utc ().to_unix ();

            /*
             * Remove artwork that has not been used within max_age.
             */
            var age_statement = prepare ("""
                DELETE FROM artwork_cache
                WHERE last_used < ?;
            """);

            age_statement.bind_int64 (
                1,
                now - max_age
            );

            step_done (age_statement);

            /*
             * Check the current cache size.
             */
            var size_statement = prepare ("""
                SELECT COALESCE(SUM(length(data)), 0)
                FROM artwork_cache;
            """);

            int64 current_size = 0;

            if (size_statement.step () == Sqlite.ROW) {
                current_size = size_statement.column_int64 (0);
            }

            /*
             * Nothing else to do if the cache is already within
             * the configured size.
             */
            if (current_size <= max_size) {
                return;
            }

            /*
             * Remove least-recently-used entries until the cache
             * is back below the configured maximum size.
             */
            var entries = prepare ("""
                SELECT
                    key,
                    length(data)
                FROM artwork_cache
                ORDER BY last_used ASC;
            """);

            var keys_to_delete = new Gee.ArrayList<string> ();

            while (
                current_size > max_size &&
                entries.step () == Sqlite.ROW
            ) {
                string key = entries.column_text (0);
                int64 size = entries.column_int64 (1);

                keys_to_delete.add (key);

                current_size -= size;
            }

            foreach (string key in keys_to_delete) {
                var delete_statement = prepare ("""
                    DELETE FROM artwork_cache
                    WHERE key = ?;
                """);

                delete_statement.bind_text (1, key);

                step_done (delete_statement);
            }
        }

        private void touch (
            string key
        ) throws Error {
            var statement = prepare ("""
                UPDATE artwork_cache
                SET
                    last_used = ?,
                    use_count = use_count + 1
                WHERE key = ?;
            """);

            statement.bind_int64 (
                1,
                new DateTime.now_utc ().to_unix ()
            );

            statement.bind_text (2, key);

            step_done (statement);
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