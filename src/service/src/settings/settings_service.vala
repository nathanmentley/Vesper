/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

using Gee;

using Vesper.Core.Plugins;
using Vesper.Core.Settings;

namespace Vesper.Service.Settings {
    public interface SettingsService : Object {
        public abstract Map<PluginKey, Gee.List<SettingDefinition>> get_setting_definitions ();
        public abstract string? get_string (SettingDefinition key);
        public abstract void set_string (SettingDefinition key, string value);
    }
}