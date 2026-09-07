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

using Vesper.Core.Models;
using Vesper.Core.Settings;

namespace Vesper.Service.Settings {
    public sealed class SettingsEngineImpl : Object, SettingsEngine {
        private KeyFile key_file;
        private string filename;

        public SettingsEngineImpl (string filename) {
            this.filename = filename;

            this.key_file = new KeyFile ();

            load ();
        }

        public string? get_string (SettingDefinition definition) {
            try {
                return key_file.get_string (definition.source, definition.key);
            } catch (KeyFileError e) {
                info ("Unable to load setting value %s - %s because: %s", definition.source, definition.key, e.message);

                return null;
            }
        }

        public void set_string (SettingDefinition definition, string value) {
            key_file.set_string (definition.source, definition.key, value);

            save ();
        }

        private void load () {
            try {
                key_file.load_from_file (filename, KeyFileFlags.NONE);
            } catch (Error e) {
                info ("Unable to load settings: %s", e.message);
            }
        }

        private void save () {
            try {
                key_file.save_to_file (filename);
            } catch (Error e) {
                warning ("Unable to save settings: %s", e.message);
            }
        }
    }
}