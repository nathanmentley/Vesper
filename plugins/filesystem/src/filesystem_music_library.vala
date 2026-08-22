/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

using PiPod.Core.Models;
using PiPod.Core.Plugins;
using PiPod.Core.Settings;

namespace PiPod.Plugins.Filesystem {
    public class FilesystemMusicLibrary :
    Plugin,
    ConfigurablePlugin,
    MusicLibrary,
    SettingsProvider,
    Object
{
        public string id { get { return "filesystem-1"; } }

        public string source { get { return "Filesystem"; } }

        private SettingDefinition directory_settings_def;

        public FilesystemMusicLibrary () {
            Object ();
        }

        public void configure (SettingsEngine settings) {
            directory_settings_def =
                new SettingDefinition (
                    id,
                    "directory",
                    "Directory",
                    "Directory Location of Media Library",
                    SettingType.STRING
                );
        }

        public Gee.List<SettingDefinition> get_setting_definitions () {
            var settings =
                new Gee.ArrayList<SettingDefinition> ();

            settings.add (directory_settings_def);

            return settings;
        }

        public async Gee.List<Artist> get_artists () {
            return Gee.List.empty ();
        }

        public async Gee.List<Album> get_albums (string artist_id) {
            return Gee.List.empty ();
        }

        public async Gee.List<Song> get_tracks (string album_id) {
            return Gee.List.empty ();
        }

        public async GLib.Bytes? get_artwork (string artwork_id) {
            return null;
        }
    }
}

[ModuleInit]
public void peas_register_types (TypeModule module) {
    Peas.ObjectModule object_module = module as Peas.ObjectModule;

    object_module.register_extension_type (typeof (MusicLibrary), typeof (PiPod.Plugins.Filesystem.FilesystemMusicLibrary));
    object_module.register_extension_type (typeof (SettingsProvider), typeof (PiPod.Plugins.Filesystem.FilesystemMusicLibrary));
}