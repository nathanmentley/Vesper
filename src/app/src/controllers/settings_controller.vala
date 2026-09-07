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
using Gee;

using Vesper.Core.Plugins;
using Vesper.Core.Settings;

using Vesper.Service.Settings;

using Vesper.App.Views;

namespace Vesper.App.Controllers {
    public class SettingsController : BaseController<SettingsView> {
        public signal void connection_requested ();

        private SettingsService settings_service;

        public SettingsController (SettingsService settings_service, Gtk.Window parent_window) {
            base (new SettingsView (settings_service, parent_window));

            this.settings_service = settings_service;

            load_settings ();

            connect_view ();
        }

        private void connect_view () {
            view.connection_requested.connect (() => {
                save_settings ();

                connection_requested ();
            });
        }

        private void load_settings () {
            Map<PluginKey, Gee.List<SettingDefinition>> settings = settings_service.get_setting_definitions ();

            foreach (PluginKey key in settings.keys) {
                var setting_definitions = settings.get (key);

                if (setting_definitions == null) {
                    continue;
                }

                foreach (SettingDefinition definition in setting_definitions) {
                    var value = settings_service.get_string (definition);

                    view.set_setting_value (key, definition, value);
                }
            }
        }

        private void save_settings () {
            Map<PluginKey, Gee.List<SettingDefinition>> settings = settings_service.get_setting_definitions ();

            foreach (PluginKey key in settings.keys) {
                var setting_definitions = settings.get (key);

                if (setting_definitions == null) {
                    continue;
                }

                foreach (SettingDefinition definition in setting_definitions) {
                    var value = view.get_setting_value (key, definition);

                    if (value == null) {
                        continue;
                    }

                    settings_service.set_string (definition, value);
                }
            }
        }
    }
}