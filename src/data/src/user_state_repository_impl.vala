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
using GLib;
using Sqlite;

using Vesper.Core.Models;

namespace Vesper.Data {
    public sealed class UserStateRepositoryImpl : UserStateRepository, Object {
        private Database database;

        public UserStateRepositoryImpl (Database database) {
            this.database = database;
        }

        public SongStats? get (string song_id) throws Error {
            var statement = prepare ("""
                SELECT song_id, play_count, total_play_seconds, last_played
                FROM song_stats
                WHERE song_id = ?;
            """);
            statement.bind_text (1, song_id);

            if (statement.step () != Sqlite.ROW) {
                return null;
            }

            return new SongStats (
                statement.column_text (0),
                statement.column_int (1),
                statement.column_int64 (2),
                nullable_int64 (statement, 3)
            );
        }

        public void record_play (
            string song_id,
            int64 played_at,
            int duration,
            bool completed
        ) throws Error {
            database.begin_transaction ();

            try {
                append_internal (song_id, played_at, duration, completed);

                var statement = prepare ("""
                    INSERT INTO song_stats (
                        song_id,
                        play_count,
                        total_play_seconds,
                        last_played
                    )
                    VALUES (?, 1, ?, ?)
                    ON CONFLICT(song_id) DO UPDATE SET
                        play_count = song_stats.play_count + 1,
                        total_play_seconds = song_stats.total_play_seconds + excluded.total_play_seconds,
                        last_played = excluded.last_played;
                """);
                statement.bind_text (1, song_id);
                statement.bind_int (2, duration);
                statement.bind_int64 (3, played_at);
                step_done (statement);

                database.commit ();
            } catch (Error e) {
                database.rollback ();
                throw e;
            }
        }

        public void append (PlayHistoryEntry entry) throws Error {
            var statement = prepare ("""
                INSERT INTO play_history (
                    song_id,
                    played_at,
                    duration,
                    completed
                )
                VALUES (?, ?, ?, ?);
            """);
            statement.bind_text (1, entry.song_id);
            statement.bind_int64 (2, entry.played_at);
            statement.bind_int (3, entry.duration);
            statement.bind_int (4, entry.completed ? 1 : 0);
            step_done (statement);
        }

        public Gee.List<PlayHistoryEntry> get_recent (int limit = 50) throws Error {
            var entries = new Gee.ArrayList<PlayHistoryEntry> ();
            var statement = prepare ("""
                SELECT id, song_id, played_at, duration, completed
                FROM play_history
                ORDER BY played_at DESC, id DESC
                LIMIT ?;
            """);
            statement.bind_int (1, limit);

            while (statement.step () == Sqlite.ROW) {
                entries.add (new PlayHistoryEntry (
                    statement.column_int64 (0),
                    statement.column_text (1),
                    statement.column_int64 (2),
                    statement.column_int (3),
                    statement.column_int (4) != 0
                ));
            }

            return entries;
        }

        public Gee.List<string> get_recent_song_ids (int limit = 50) throws Error {
            return get_ids ("""
                SELECT song_id
                FROM play_history
                GROUP BY song_id
                ORDER BY MAX(played_at) DESC, song_id
                LIMIT ?;
            """, limit);
        }

        public Gee.List<string> get_most_played_song_ids (int limit = 50) throws Error {
            return get_ids ("""
                SELECT song_id
                FROM song_stats
                WHERE play_count > 0
                ORDER BY play_count DESC, last_played DESC, song_id
                LIMIT ?;
            """, limit);
        }

        public Gee.List<string> get_never_played_song_ids (int limit = 50) throws Error {
            return get_ids ("""
                SELECT s.id
                FROM songs s
                WHERE NOT EXISTS (
                    SELECT 1 FROM song_stats ss WHERE ss.song_id = s.id
                )
                ORDER BY s.added_at DESC, s.id
                LIMIT ?;
            """, limit);
        }

        public void cleanup (
            int64 retention_seconds = 90 * 24 * 60 * 60,
            int maximum_events = 1000
        ) throws Error {
            int64 cutoff = new DateTime.now_utc ().to_unix () - retention_seconds;
            var statement = prepare ("""
                DELETE FROM play_history
                WHERE played_at < ?
                   OR id NOT IN (
                       SELECT id
                       FROM play_history
                       ORDER BY played_at DESC, id DESC
                       LIMIT ?
                   );
            """);
            statement.bind_int64 (1, cutoff);
            statement.bind_int (2, maximum_events);
            step_done (statement);
        }

        public bool is_favorite (string song_id) throws Error {
            var statement = prepare (
                "SELECT 1 FROM song_favorites WHERE song_id = ?;"
            );
            statement.bind_text (1, song_id);
            return statement.step () == Sqlite.ROW;
        }

        public void add_favorite (string song_id) throws Error {
            var statement = prepare (
                "INSERT OR IGNORE INTO song_favorites (song_id) VALUES (?);"
            );
            statement.bind_text (1, song_id);
            step_done (statement);
        }

        public void remove_favorite (string song_id) throws Error {
            var statement = prepare (
                "DELETE FROM song_favorites WHERE song_id = ?;"
            );
            statement.bind_text (1, song_id);
            step_done (statement);
        }

        public Gee.List<string> get_favorite_song_ids () throws Error {
            var song_ids = new Gee.ArrayList<string> ();
            var statement = prepare (
                "SELECT song_id FROM song_favorites ORDER BY song_id;"
            );
            while (statement.step () == Sqlite.ROW) {
                song_ids.add (statement.column_text (0));
            }
            return song_ids;
        }

        private void append_internal (
            string song_id,
            int64 played_at,
            int duration,
            bool completed
        ) throws Error {
            var statement = prepare ("""
                INSERT INTO play_history (song_id, played_at, duration, completed)
                VALUES (?, ?, ?, ?);
            """);
            statement.bind_text (1, song_id);
            statement.bind_int64 (2, played_at);
            statement.bind_int (3, duration);
            statement.bind_int (4, completed ? 1 : 0);
            step_done (statement);
        }

        private Gee.List<string> get_ids (string sql, int limit) throws Error {
            var ids = new Gee.ArrayList<string> ();
            var statement = prepare (sql);
            statement.bind_int (1, limit);
            while (statement.step () == Sqlite.ROW) {
                ids.add (statement.column_text (0));
            }
            return ids;
        }

        private Sqlite.Statement prepare (string sql) throws Error {
            Sqlite.Statement statement;
            int result = database.connection.prepare_v2 (sql, -1, out statement);
            if (result != Sqlite.OK) {
                throw new IOError.FAILED (
                    "Failed to prepare SQL statement: %s".printf (
                        database.connection.errmsg ()
                    )
                );
            }
            return statement;
        }

        private void step_done (Sqlite.Statement statement) throws Error {
            if (statement.step () != Sqlite.DONE) {
                throw new IOError.FAILED (
                    "SQLite statement failed: %s".printf (
                        database.connection.errmsg ()
                    )
                );
            }
        }

        private int64? nullable_int64 (
            Sqlite.Statement statement,
            int index
        ) {
            if (statement.column_type (index) == Sqlite.NULL) {
                return null;
            }
            return statement.column_int64 (index);
        }
    }
}
