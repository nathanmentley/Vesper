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

using Vesper.Core.Models;
using Vesper.Core.Plugins;
using Vesper.Core.Settings;

namespace Vesper.Plugins.Filesystem {
    public sealed class Config: Object {
        private SettingsEngine settings;
        private SettingDefinition directory_settings_def;

        public string directory {
            owned get {
                return settings.get_string(directory_settings_def);
            }
        }

        public Config (SettingsEngine settings, SettingDefinition directory_settings_def) {
            this.settings = settings;
            this.directory_settings_def = directory_settings_def;
        }
    }
}