/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

using GLib;
using Gee;

using Vesper.Core.Models;
using Vesper.Core.Plugins;

using Vesper.Data;

namespace Vesper.Service.Libraries {
    public sealed class LibraryServiceImpl : LibraryService, Object {
        private Gee.List<MusicLibrary> music_libraries;
        private LibraryRepository library_repository;

        public LibraryServiceImpl (LibraryRepository library_repository, Gee.List<MusicLibrary> music_libraries) {
            this.library_repository = library_repository;
            this.music_libraries = music_libraries;
        }

        public async void sync () {
            //TODO: This is entirely upsert, and needs to support deletion.
            //  This should also batch mutations into a single transaction, and should be cancellable.
            //  This should also be a background task, and should not block the main thread.
            //  This should also be able to be invoked on a single library, artist, album, or track.
            foreach (MusicLibrary music_library in music_libraries) {
                if (!stale_check (music_library.get_id ())) {
                    continue;
                }

                library_repository.save_library (
                    music_library.get_id (),
                    music_library.get_id (),
                    music_library.get_id (),
                    0
                );

                Gee.List<Artist> artists = yield music_library.get_artists ();

                foreach (Artist artist in artists) {
                    library_repository.save_artist (
                        music_library.get_id (),
                        artist
                    );

                    Gee.List<Album> albums = yield music_library.get_albums (artist.id);

                    foreach (Album album in albums) {
                        library_repository.save_album (
                            music_library.get_id (),
                            artist.id,
                            album
                        );

                        Gee.List<Song> tracks = yield music_library.get_tracks (album.id);

                        foreach (Song track in tracks) {
                            library_repository.save_song (
                                music_library.get_id (),
                                artist.id,
                                track
                            );
                        }
                    }
                }

                library_repository.save_library (
                    music_library.get_id (),
                    music_library.get_id (),
                    music_library.get_id (),
                    new DateTime.now_utc ().to_unix ()
                );
            }

            library_refresh ();
        }

        public async Gee.List<Artist> get_artists () {
            Gee.List<Artist> result = new Gee.ArrayList<Artist> ();

            foreach (MusicLibrary music_library in music_libraries) {
                Gee.List<Artist> artists = library_repository.get_artists (music_library.get_id ());

                if (artists.size > 0) {
                    result.add_all (artists);
                }
            }

            return result;
        }

        public async Gee.List<Album> get_albums (string music_library_id, string artist_id) {
            Gee.List<Album> result = new Gee.ArrayList<Album> ();

            foreach (MusicLibrary music_library in music_libraries) {
                if (music_library.get_id () != music_library_id) {
                    continue;
                }

                Gee.List<Album> albums = library_repository.get_albums (artist_id);

                if (albums.size > 0) {
                    result.add_all (albums);
                }
            }

            return result;
        }

        public async Gee.List<Song> get_tracks (string music_library_id, string artist_id, string album_id) {
            Gee.List<Song> result = new Gee.ArrayList<Song> ();

            foreach (MusicLibrary music_library in music_libraries) {
                if (music_library.get_id () != music_library_id) {
                    continue;
                }

                Gee.List<Song> tracks = library_repository.get_tracks (album_id);

                if (tracks.size > 0) {
                    result.add_all (tracks);
                }
            }

            return result;
        }

        public async Song? get_track (string song_id) {
            foreach (MusicLibrary music_library in music_libraries) {
                Song? track = library_repository.get_track (music_library.get_id (), song_id);

                if (track != null) {
                    return track;
                }
            }

            return null;
        }

        public async GLib.Bytes? get_artwork (Song song) {
            foreach (MusicLibrary music_library in music_libraries) {
                GLib.Bytes? artwork = yield music_library.get_artwork (song);

                if (artwork != null) {
                    return artwork;
                }
            }

            return null;
        }

        private bool stale_check (string music_library_id) {
            Library? library = library_repository.get_library (music_library_id);

            if (library == null) {
                return true;
            }

            DateTime now = new DateTime.now_utc ();

            DateTime one_hour_ago = now.add_hours (-1);

            return library.last_synced < one_hour_ago.to_unix ();            
        }
    }
}