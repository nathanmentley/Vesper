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

using Gtk;
using Adw;

using PiPod.Core.Models;
using PiPod.Core.Plugins;
using PiPod.Core.Settings;

using PiPod.App.Utils;

namespace PiPod.App.Views {
    public class SettingsView : BaseView {
        public signal void connection_requested ();

        private Button connect_button;

        private Gee.List<SettingsProvider> setting_providers;

        private Gee.HashMap<string, Adw.EntryRow> setting_rows;

        public SettingsView (
            Gee.List<SettingsProvider> setting_providers
        ) {
            Object (
                orientation: Orientation.VERTICAL,
                spacing: 0
            );

            this.setting_providers =
                setting_providers;

            this.setting_rows =
                new Gee.HashMap<string, Adw.EntryRow> ();

            build_ui ();
            connect_signals ();
        }

        private void build_ui () {
            /*
             * ---------------------------------------------------------
             * Content
             * ---------------------------------------------------------
             */

            var content =
                new Gtk.Box (
                    Orientation.VERTICAL,
                    0
                );

            content.hexpand = true;
            content.vexpand = true;

            /*
             * ---------------------------------------------------------
             * Settings providers
             * ---------------------------------------------------------
             */

            foreach (var provider in setting_providers) {
                var group =
                    create_provider_group (
                        provider
                    );

                content.append (
                    group
                );
            }

            /*
             * ---------------------------------------------------------
             * Connect button
             * ---------------------------------------------------------
             *
             * Settings are displayed above.
             * Connecting is an action, so it deliberately lives
             * outside the PreferencesGroups.
             */

            var button_box =
                new Gtk.Box (
                    Orientation.HORIZONTAL,
                    0
                );

            button_box.halign =
                Align.CENTER;

            button_box.margin_top =
                12;

            button_box.margin_bottom =
                12;

            connect_button =
                new Gtk.Button.with_label (
                    "Connect"
                );

            connect_button.add_css_class (
                "suggested-action"
            );

            connect_button.add_css_class (
                "pill"
            );

            connect_button.width_request =
                140;

            button_box.append (
                connect_button
            );

            content.append (
                button_box
            );

            /*
             * ---------------------------------------------------------
             * Mount
             * ---------------------------------------------------------
             */

            append (
                content
            );
        }

        private Adw.PreferencesGroup create_provider_group (
            SettingsProvider provider
        ) {
            var group =
                new Adw.PreferencesGroup ();

            group.title =
                provider.source;

            foreach (
                var definition
                in provider.get_setting_definitions ()
            ) {
                var row =
                    create_setting_row (
                        provider,
                        definition
                    );

                if (row != null) {
                    group.add (
                        row
                    );
                }
            }

            return group;
        }

        private Adw.PreferencesRow? create_setting_row (
            SettingsProvider provider,
            SettingDefinition definition
        ) {
            switch (definition.setting_type) {
                case SettingType.STRING:
                    return create_string_row (
                        provider,
                        definition
                    );

                case SettingType.PASSWORD:
                    return create_password_row (
                        provider,
                        definition
                    );

                case SettingType.DIRECTORY:
                    return create_directory_row (
                        provider,
                        definition
                    );

                default:
                    warning (
                        "Unknown setting type for '%s'",
                        definition.key
                    );

                    return null;
            }
        }

        private Adw.EntryRow create_string_row (
            SettingsProvider provider,
            SettingDefinition definition
        ) {
            var row =
                new Adw.EntryRow ();

            row.title =
                definition.name;

            if (definition.description != "") {
                row.tooltip_text =
                    definition.description;
            }

            register_setting_row (
                provider,
                definition,
                row
            );

            return row;
        }

        private Adw.PasswordEntryRow create_password_row (
            SettingsProvider provider,
            SettingDefinition definition
        ) {
            var row =
                new Adw.PasswordEntryRow ();

            row.title =
                definition.name;

            if (definition.description != "") {
                row.tooltip_text =
                    definition.description;
            }

            register_setting_row (
                provider,
                definition,
                row
            );

            return row;
        }

        private Adw.EntryRow create_directory_row (
            SettingsProvider provider,
            SettingDefinition definition
        ) {
            /*
             * For now DIRECTORY behaves like a string.
             *
             * This can later become an Adw.ActionRow with a
             * Gtk.FileDialog folder picker.
             */

            var row =
                new Adw.EntryRow ();

            row.title =
                definition.name;

            if (definition.description != "") {
                row.tooltip_text =
                    definition.description;
            }

            register_setting_row (
                provider,
                definition,
                row
            );

            return row;
        }

        private void register_setting_row (
            SettingsProvider provider,
            SettingDefinition definition,
            Adw.EntryRow row
        ) {
            setting_rows.set (
                get_setting_id (
                    provider,
                    definition
                ),
                row
            );
        }

        /*
         * -------------------------------------------------------------
         * Public setting access
         * -------------------------------------------------------------
         */

        public string? get_setting_value (
            SettingsProvider provider,
            SettingDefinition definition
        ) {
            var row =
                get_setting_row (
                    provider,
                    definition
                );

            if (row == null) {
                return null;
            }

            return row.text;
        }

        public void set_setting_value (
            SettingsProvider provider,
            SettingDefinition definition,
            string? value
        ) {
            var row =
                get_setting_row (
                    provider,
                    definition
                );

            if (row == null) {
                return;
            }

            row.text =
                value ?? "";
        }

        private Adw.EntryRow? get_setting_row (
            SettingsProvider provider,
            SettingDefinition definition
        ) {
            return setting_rows.get (
                get_setting_id (
                    provider,
                    definition
                )
            );
        }

        /*
         * -------------------------------------------------------------
         * Setting identity
         * -------------------------------------------------------------
         *
         * Setting keys are only unique within a plugin.
         *
         * For example:
         *
         *     navidrome/server_url
         *     jellyfin/server_url
         *
         * are different settings.
         */

        private string get_setting_id (
            SettingsProvider provider,
            SettingDefinition definition
        ) {
            return "%s/%s".printf (
                provider.id,
                definition.key
            );
        }

        /*
         * -------------------------------------------------------------
         * Signals
         * -------------------------------------------------------------
         */

        private void connect_signals () {
            connect_button.clicked.connect (() => {
                connection_requested ();
            });
        }
    }
}