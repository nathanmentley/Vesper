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
    public class PlaylistRepository : Object {
        private Database database;

        public PlaylistRepository (Database database) {
            this.database = database;
        }

        public void save_playlist (
            Playlist playlist
        ) throws Error {
            var statement = prepare ("""
                INSERT INTO playlists (
                    id,
                    name
                )
                VALUES (?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    name = excluded.name;
            """);

            statement.bind_text (1, playlist.id);
            statement.bind_text (2, playlist.name);

            step_done (statement);
        }

        public void delete_playlist (
            string playlist_id
        ) throws Error {
            var statement = prepare ("""
                DELETE FROM playlists
                WHERE id = ?;
            """);

            statement.bind_text (1, playlist_id);

            step_done (statement);
        }

        public Playlist? get_playlist (
            string playlist_id
        ) throws Error {
            var statement = prepare ("""
                SELECT
                    p.id,
                    p.name,
                    COUNT(ps.id) AS song_count
                FROM playlists p
                LEFT JOIN playlist_songs ps
                    ON ps.playlist_id = p.id
                WHERE p.id = ?
                GROUP BY p.id, p.name;
            """);

            statement.bind_text (1, playlist_id);

            if (statement.step () != Sqlite.ROW) {
                return null;
            }

            return new Playlist (
                statement.column_text (0),
                statement.column_text (1),
                statement.column_int (2),
                0,
                null
            );
        }

        public Gee.List<Playlist> get_playlists () throws Error {
            var playlists =
                new Gee.ArrayList<Playlist> ();

            var statement = prepare ("""
                SELECT
                    p.id,
                    p.name,
                    COUNT(ps.id) AS song_count
                FROM playlists p
                LEFT JOIN playlist_songs ps
                    ON ps.playlist_id = p.id
                GROUP BY p.id, p.name
                ORDER BY p.name;
            """);

            while (statement.step () == Sqlite.ROW) {
                playlists.add (
                    new Playlist (
                        statement.column_text (0),
                        statement.column_text (1),
                        statement.column_int (2),
                        0,
                        null
                    )
                );
            }

            return playlists;
        }

        public PlaylistItem? get_item (
            string item_id
        ) throws Error {
            var statement = prepare ("""
                SELECT
                    id,
                    playlist_id,
                    song_id,
                    position
                FROM playlist_songs
                WHERE id = ?;
            """);

            statement.bind_text (1, item_id);

            if (statement.step () != Sqlite.ROW) {
                return null;
            }

            return new PlaylistItem (
                statement.column_text (0),
                statement.column_text (1),
                statement.column_text (2),
                statement.column_int (3)
            );
        }

        public Gee.List<PlaylistItem> get_items (
            string playlist_id
        ) throws Error {
            var entries =
                new Gee.ArrayList<PlaylistItem> ();

            var statement = prepare ("""
                SELECT
                    id,
                    playlist_id,
                    song_id,
                    position
                FROM playlist_songs
                WHERE playlist_id = ?
                ORDER BY position;
            """);

            statement.bind_text (1, playlist_id);

            while (statement.step () == Sqlite.ROW) {
                entries.add (
                    new PlaylistItem (
                        statement.column_text (0),
                        statement.column_text (1),
                        statement.column_text (2),
                        statement.column_int (3)
                    )
                );
            }

            return entries;
        }

        public void add_item (
            PlaylistItem item
        ) throws Error {
            var statement = prepare ("""
                INSERT INTO playlist_songs (
                    id,
                    playlist_id,
                    song_id,
                    position
                )
                VALUES (?, ?, ?, ?);
            """);

            statement.bind_text (1, item.id);
            statement.bind_text (2, item.playlist_id);
            statement.bind_text (3, item.song_id);
            statement.bind_int (4, item.position);

            step_done (statement);
        }

        public void remove_item (
            string item_id
        ) throws Error {
            var statement = prepare ("""
                DELETE FROM playlist_songs
                WHERE id = ?;
            """);

            statement.bind_text (1, item_id);

            step_done (statement);
        }

        public void clear_items (
            string playlist_id
        ) throws Error {
            var statement = prepare ("""
                DELETE FROM playlist_songs
                WHERE playlist_id = ?;
            """);

            statement.bind_text (1, playlist_id);

            step_done (statement);
        }

        public void reorder_item (
            string item_id,
            int new_position
        ) throws Error {
            var entries = get_item_context (item_id);

            if (entries == null) {
                throw new IOError.NOT_FOUND (
                    "Playlist item '%s' was not found".printf (
                        item_id
                    )
                );
            }

            string playlist_id = entries[0];
            int old_position = entries[1].to_int ();

            if (old_position == new_position) {
                return;
            }

            var max_position = get_max_position (playlist_id);

            if (max_position < 0) {
                return;
            }

            new_position = int.max (
                0,
                int.min (new_position, max_position)
            );

            database.begin_transaction ();

            try {
                // Temporarily move the item outside the normal
                // position range so that it cannot collide with
                // another position while we shift the other entries.
                var temp_statement = prepare ("""
                    UPDATE playlist_songs
                    SET position = -1
                    WHERE id = ?;
                """);

                temp_statement.bind_text (1, item_id);
                step_done (temp_statement);

                if (new_position < old_position) {
                    var statement = prepare ("""
                        UPDATE playlist_songs
                        SET position = position + 1
                        WHERE playlist_id = ?
                          AND position >= ?
                          AND position < ?;
                    """);

                    statement.bind_text (1, playlist_id);
                    statement.bind_int (2, new_position);
                    statement.bind_int (3, old_position);

                    step_done (statement);
                } else {
                    var statement = prepare ("""
                        UPDATE playlist_songs
                        SET position = position - 1
                        WHERE playlist_id = ?
                          AND position > ?
                          AND position <= ?;
                    """);

                    statement.bind_text (1, playlist_id);
                    statement.bind_int (2, old_position);
                    statement.bind_int (3, new_position);

                    step_done (statement);
                }

                var final_statement = prepare ("""
                    UPDATE playlist_songs
                    SET position = ?
                    WHERE id = ?;
                """);

                final_statement.bind_int (1, new_position);
                final_statement.bind_text (2, item_id);

                step_done (final_statement);

                database.commit ();
            } catch (Error e) {
                database.rollback ();
                throw e;
            }
        }

        private string[]? get_item_context (
            string item_id
        ) throws Error {
            var statement = prepare ("""
                SELECT playlist_id, position
                FROM playlist_songs
                WHERE id = ?;
            """);

            statement.bind_text (1, item_id);

            if (statement.step () != Sqlite.ROW) {
                return null;
            }

            return {
                statement.column_text (0),
                statement.column_int (1).to_string ()
            };
        }

        private int get_max_position (
            string playlist_id
        ) throws Error {
            var statement = prepare ("""
                SELECT COALESCE(MAX(position), -1)
                FROM playlist_songs
                WHERE playlist_id = ?;
            """);

            statement.bind_text (1, playlist_id);

            if (statement.step () != Sqlite.ROW) {
                return -1;
            }

            return statement.column_int (0);
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