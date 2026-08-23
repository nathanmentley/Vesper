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
        private Config config;

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

            config = new Config (settings, directory_settings_def);
        }

        public Gee.List<SettingDefinition> get_setting_definitions () {
            var settings =
                new Gee.ArrayList<SettingDefinition> ();

            settings.add (directory_settings_def);

            return settings;
        }

        public async GLib.Bytes? get_artwork (Song song) {
            return null;
        }

        public async Gee.List<Artist> get_artists () {
            var artists = new Gee.ArrayList<Artist> ();
            var directory = File.new_for_path (config.directory);

            try {
                var enumerator = directory.enumerate_children (
                    FileAttribute.STANDARD_NAME + "," +
                    FileAttribute.STANDARD_TYPE,
                    FileQueryInfoFlags.NONE
                );

                FileInfo info;

                while ((info = enumerator.next_file ()) != null) {
                    if (info.get_file_type () != FileType.DIRECTORY) {
                        continue;
                    }

                    var name = info.get_name ();

                    // Ignore hidden directories.
                    if (name.has_prefix (".")) {
                        continue;
                    }

                    var artist_directory = directory.get_child (name);

                    artists.add (
                        new Artist (
                            artist_directory.get_path (),
                            name
                        )
                    );
                }
            } catch (Error e) {
                warning (
                    "Failed to enumerate music library '%s': %s",
                    config.directory,
                    e.message
                );
            }

            artists.sort ((a, b) => {
                return a.name.collate (b.name);
            });

            return artists;
        }

        public async Gee.List<Album> get_albums (string artist_id) {
            var albums = new Gee.ArrayList<Album> ();
            var artist_directory = File.new_for_path (artist_id);

            try {
                var enumerator = artist_directory.enumerate_children (
                    FileAttribute.STANDARD_NAME + "," +
                    FileAttribute.STANDARD_TYPE,
                    FileQueryInfoFlags.NONE
                );

                FileInfo info;

                while ((info = enumerator.next_file ()) != null) {
                    if (info.get_file_type () != FileType.DIRECTORY) {
                        continue;
                    }

                    var name = info.get_name ();

                    if (name.has_prefix (".")) {
                        continue;
                    }

                    var album_directory = artist_directory.get_child (name);
                    var cover = find_cover (album_directory);

                    albums.add (
                        new Album (
                            album_directory.get_path (),
                            name,
                            cover
                        )
                    );
                }
            } catch (Error e) {
                warning (
                    "Failed to enumerate artist directory '%s': %s",
                    artist_id,
                    e.message
                );
            }

            albums.sort ((a, b) => {
                return a.name.collate (b.name);
            });

            return albums;
        }

        public async Gee.List<Song> get_tracks (string album_id) {
            var songs = new Gee.ArrayList<Song> ();
            var album_directory = File.new_for_path (album_id);

            try {
                var album_name = album_directory.get_basename ();

                var artist_directory = album_directory.get_parent ();

                string artist_name = "";
                if (artist_directory != null) {
                    artist_name = artist_directory.get_basename ();
                }

                var album = new Album (
                    album_directory.get_path (),
                    album_name,
                    find_cover (album_directory)
                );

                var enumerator = album_directory.enumerate_children (
                    FileAttribute.STANDARD_NAME + "," +
                    FileAttribute.STANDARD_TYPE,
                    FileQueryInfoFlags.NONE
                );

                FileInfo info;

                while ((info = enumerator.next_file ()) != null) {
                    if (info.get_file_type () != FileType.REGULAR) {
                        continue;
                    }

                    var filename = info.get_name ();

                    if (!is_audio_file (filename)) {
                        continue;
                    }

                    var song_file = album_directory.get_child (filename);

                    // Strip the extension for the display title.
                    var title = filename;
                    var dot = title.last_index_of (".");

                    if (dot > 0) {
                        title = title.substring (0, dot);
                    }

                    songs.add (
                        new Song (
                            song_file.get_path (),
                            title,
                            song_file.get_uri (),
                            album
                        )
                    );
                }
            } catch (Error e) {
                warning (
                    "Failed to enumerate album directory '%s': %s",
                    album_id,
                    e.message
                );
            }

            songs.sort ((a, b) => {
                return a.title.collate (b.title);
            });

            return songs;
        }

        private static bool is_audio_file (string filename) {
            var lower = filename.down ();

            return lower.has_suffix (".mp3") ||
                   lower.has_suffix (".flac") ||
                   lower.has_suffix (".ogg") ||
                   lower.has_suffix (".oga") ||
                   lower.has_suffix (".opus") ||
                   lower.has_suffix (".m4a") ||
                   lower.has_suffix (".aac") ||
                   lower.has_suffix (".wav") ||
                   lower.has_suffix (".webm");
        }

        private static string? find_cover (GLib.File directory) {
            string[] names = {
                "cover.jpg",
                "cover.jpeg",
                "cover.png",
                "folder.jpg",
                "folder.jpeg",
                "folder.png",
                "album.jpg",
                "album.jpeg",
                "album.png"
            };

            foreach (var name in names) {
                var file = directory.get_child (name);

                try {
                    if (file.query_exists ()) {
                        return file.get_uri ();
                    }
                } catch (Error e) {
                    // Ignore files that cannot be queried.
                }
            }

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