/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

using GLib;

using PiPod.Core.Models;

namespace PiPod.Core.Settings {
    public interface SettingsEngine : Object {
        public abstract string? get_string (SettingDefinition key);
        public abstract void set_string (SettingDefinition key, string value);
    }

    public sealed class SettingsEngineImpl : Object, SettingsEngine {
        private KeyFile key_file;
        private string filename;

        public SettingsEngineImpl (
            string filename
        ) {
            this.filename =
                filename;

            this.key_file =
                new KeyFile ();

            load ();
        }

        public string? get_string (
            SettingDefinition definition
        ) {
            try {
                return key_file.get_string (
                    definition.source,
                    definition.key
                );
            } catch (KeyFileError e) {
                return null;
            }
        }

        public void set_string (
            SettingDefinition definition,
            string value
        ) {
            key_file.set_string (
                definition.source,
                definition.key,
                value
            );

            save ();
        }

        private void load () {
            try {
                key_file.load_from_file (
                    filename,
                    KeyFileFlags.NONE
                );
            } catch (Error e) {
                /*
                 * Missing configuration is fine.
                 *
                 * The file will be created when the first
                 * setting is saved.
                 */
            }
        }

        private void save () {
            try {
                key_file.save_to_file (
                    filename
            );
            } catch (Error e) {
                warning (
                    "Unable to save settings: %s",
                    e.message
                );
            }
        }
    }
}