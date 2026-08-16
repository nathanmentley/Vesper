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

using PiPod.Core.Utils;

namespace PiPod.Core {
    public interface IConfig : Object {
        public abstract string base_url { get; set; }

        public abstract string user { get; set; }

        public abstract string pass { get; set; }

        public abstract void save_config ();

        public abstract bool load_config ();

        public static IConfig create () {
            return new Config ();
        }

        private sealed class Config : IConfig, Object {
            private static string CONFIG_FILE = "pipod-config.ini";
            private static string PIPOD_CONIFG_ROOT = "pipod";
            private static string PIPOD_CONFIG_BASE_URL = "base_url";
            private static string PIPOD_CONFIG_USER = "user";
            private static string PIPOD_CONFIG_PASS = "pass";
    
            public string base_url { get; set; }

            public string user { get; set; }

            public string pass { get; set; }
    
            public void save_config () {
                KeyFile kf = new KeyFile();

                kf.set_value (PIPOD_CONIFG_ROOT, PIPOD_CONFIG_BASE_URL, base_url);
                kf.set_value (PIPOD_CONIFG_ROOT, PIPOD_CONFIG_USER, user);
                kf.set_value (PIPOD_CONIFG_ROOT, PIPOD_CONFIG_PASS, pass);

                try {
                    kf.save_to_file (CONFIG_FILE);
                } catch (Error e) {
                    // TODO: Add logging

                    // best effort, if we fail to save sorry. :/
                }
            }
    
            public bool load_config () {
                base_url = StringUtils.EMPTY;
                user = StringUtils.EMPTY;
                pass = StringUtils.EMPTY;

                KeyFile kf = new KeyFile();

                try {
                    kf.load_from_file (CONFIG_FILE, KeyFileFlags.NONE);

                    base_url = kf.get_string (PIPOD_CONIFG_ROOT, PIPOD_CONFIG_BASE_URL);
                    user = kf.get_string (PIPOD_CONIFG_ROOT, PIPOD_CONFIG_USER);
                    pass = kf.get_string (PIPOD_CONIFG_ROOT, PIPOD_CONFIG_PASS);

                    return true;
                } catch (Error e) {
                    // best effort, if failed to load config or parse error — treat as empty
                    return false;
                }
            }
        }
    }
}