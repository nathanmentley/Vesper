/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

using GLib;

using Vesper.Core.Models;

namespace Vesper.Core.Settings {
    public interface SettingsEngine : Object {
        public abstract string? get_string (SettingDefinition key);
        public abstract void set_string (SettingDefinition key, string value);
    }
}