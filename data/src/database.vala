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

namespace PiPod.Data {
    public class Database : Object {
        private Sqlite.Database db;

        public Database (string path) throws Error {
            int result = Sqlite.Database.open (path, out db);

            if (result != Sqlite.OK) {
                throw new IOError.FAILED (
                    "Failed to open database '%s': %s".printf (
                        path,
                        db.errmsg ()
                    )
                );
            }

            // Foreign keys are disabled by default in SQLite.
            exec ("PRAGMA foreign_keys = ON;");

            Migration.migrate (db);
        }

        public Sqlite.Database connection {
            get {
                return db;
            }
        }

        public void exec (string sql) throws Error {
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

        public void begin_transaction () throws Error {
            exec ("BEGIN TRANSACTION;");
        }

        public void commit () throws Error {
            exec ("COMMIT;");
        }

        public void rollback () throws Error {
            exec ("ROLLBACK;");
        }
    }
}