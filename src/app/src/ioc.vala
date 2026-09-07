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

using Vesper.Core.Models;
using Vesper.Core.Plugins;
using Vesper.Core.Settings;

using Vesper.Data;

using Vesper.Service.Libraries;
using Vesper.Service.Media;
using Vesper.Service.Playlists;
using Vesper.Service.Plugins;
using Vesper.Service.Settings;
using Vesper.Service.UserState;

using Vesper.App.Windows;

namespace Vesper.App {
    public class IOC : Object {
        public LibraryService library_service { get; private set; }
        public MediaService media_service { get; private set; }
        public SettingsService settings_service { get; private set; }
        public PlaylistService playlist_service { get; private set; }
        public UserStateService user_state_service { get; private set; }

        public IOC () {
            Object ();

            SettingsEngine settings = new SettingsEngineImpl("vesper-config.ini");

            SettingDefinition database_directory_setting = new SettingDefinition (
                "general",
                "database-directory",
                "",
                "",
                SettingType.STRING
            );

            string data_directory = settings.get_string (database_directory_setting) ?? "./data";

            Database database = new DatabaseImpl (data_directory);

            ArtworkCacheRepository artwork_cache_repository = new ArtworkCacheRepositoryImpl (database);
            PlaylistRepository playlist_repository = new PlaylistRepositoryImpl (database);
            LibraryRepository library_repository = new LibraryRepositoryImpl (database);
            UserStateRepository user_state_repository = new UserStateRepositoryImpl (database);

            SettingDefinition plugin_directory_setting = new SettingDefinition (
                "general",
                "plugin-directory",
                "",
                "",
                SettingType.STRING
            );

            string plugin_directory = settings.get_string (plugin_directory_setting) ?? "./plugins";

            PluginManager plugin_manager = new PluginManager(plugin_directory);

            Gee.List<SettingsProvider> setting_providers = get_plugin_impls (plugin_manager, settings, typeof(SettingsProvider));
            Gee.List<MusicLibrary> libraries = get_plugin_impls (plugin_manager, settings, typeof(MusicLibrary));
            MusicEngine music_engine = get_first_plugin_impl (plugin_manager, settings, typeof(MusicEngine));

            library_service = new LibraryServiceImpl (library_repository, artwork_cache_repository, libraries);
            media_service = new MediaServiceImpl (music_engine);
            settings_service = new SettingsServiceImpl (settings, setting_providers);
            playlist_service = new PlaylistServiceImpl (playlist_repository, library_service);
            user_state_service = new UserStateServiceImpl (
                user_state_repository,
                library_service
            );
        }

        private T get_first_plugin_impl<T> (
            PluginManager plugin_manager,
            SettingsEngine settings,
            GLib.Type type
        ) {
            Gee.List<GLib.Object> extensions =
                plugin_manager.get_extensions (settings, type);

            foreach (var extension in extensions) {
                if (extension.get_type ().is_a (type)) {
                    return (T) extension;
                }
            }

            error (
                "No implementation found for %s",
                type.name ()
            );
        }

        private Gee.List<T> get_plugin_impls<T> (
            PluginManager plugin_manager,
            SettingsEngine settings,
            GLib.Type type
        ) {
            Gee.List<T> result = new Gee.ArrayList<T> ();

            Gee.List<GLib.Object> extensions =
                plugin_manager.get_extensions (settings, type);

            foreach (var extension in extensions) {
                if (extension.get_type ().is_a (type)) {
                    result.add((T) extension);
                }
            }

            return result;
        }
    }
}
