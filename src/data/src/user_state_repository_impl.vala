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
