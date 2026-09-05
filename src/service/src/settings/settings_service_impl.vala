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
    public sealed class SettingsServiceImpl : SettingsService, Object {
        private SettingsEngine settings;
        private Gee.List<SettingsProvider> settings_providers;

        public SettingsServiceImpl (SettingsEngine settings, Gee.List<SettingsProvider> settings_providers) {
            this.settings = settings;
            this.settings_providers = settings_providers;
        }

        public Map<PluginKey, Gee.List<SettingDefinition>> get_setting_definitions () {
            Map<PluginKey, Gee.List<SettingDefinition>> setting_definitions =
                new HashMap<PluginKey, Gee.List<SettingDefinition>> (PluginKey.hash, PluginKey.equal);

            foreach (SettingsProvider settings_provider in settings_providers) {
                setting_definitions[settings_provider.key] = settings_provider.get_setting_definitions ();
            }

            return setting_definitions;
        }

        public string? get_string (SettingDefinition key) {
            return settings.get_string (key);
        }

        public void set_string (SettingDefinition key, string value) {
            settings.set_string (key, value);
        }
    }
}