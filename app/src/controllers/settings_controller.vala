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

using PiPod.Core.Plugins;
using PiPod.Core.Settings;

using PiPod.Views;

namespace PiPod.Controllers {
    public class SettingsController : BaseController<SettingsView> {
        public signal void connection_requested ();

        private SettingsEngine settings_engine;

        private Gee.List<SettingsProvider> setting_providers;

        public SettingsController (
            SettingsEngine settings_engine,
            Gee.List<SettingsProvider> setting_providers
        ) {
            base (
                new SettingsView (
                    setting_providers
                )
            );

            this.settings_engine =
                settings_engine;

            this.setting_providers =
                setting_providers;

            load_settings ();
        }

        protected override void connect_view () {
            view.connection_requested.connect (() => {
                save_settings ();

                connection_requested ();
            });
        }

        /*
         * -------------------------------------------------------------
         * Load
         * -------------------------------------------------------------
         */

        private void load_settings () {
            foreach (var provider in setting_providers) {
                var definitions =
                    provider.get_setting_definitions ();

                foreach (var definition in definitions) {
                    var value =
                        settings_engine.get_string (
                            definition
                        );

                    view.set_setting_value (
                        provider,
                        definition,
                        value
                    );
                }
            }
        }

        /*
         * -------------------------------------------------------------
         * Save
         * -------------------------------------------------------------
         */

        private void save_settings () {
            foreach (var provider in setting_providers) {
                var definitions =
                    provider.get_setting_definitions ();

                foreach (var definition in definitions) {
                    var value =
                        view.get_setting_value (
                            provider,
                            definition
                        );

                    if (value == null) {
                        continue;
                    }

                    settings_engine.set_string (
                        definition,
                        value
                    );
                }
            }
        }
    }
}