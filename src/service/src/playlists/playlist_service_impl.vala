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

using Gee;
using Vesper.Core.Models;
using Vesper.Service.Libraries;
using Vesper.Data;

namespace Vesper.Service.Playlists {
    public sealed class PlaylistServiceImpl : PlaylistService, Object {
        private PlaylistRepository repository;
        private LibraryService library_service;

        public PlaylistServiceImpl (
            PlaylistRepository repository,
            LibraryService library_service
        ) {
            this.repository = repository;
            this.library_service = library_service;
        }

        public async Gee.List<Playlist> get_playlists () {
            var playlists =
                new Gee.ArrayList<Playlist> ();

            try {
                playlists.add_all (
                    repository.get_playlists ()
                );
            } catch (Error e) {
                warning (
                    "Failed to get playlists: %s",
                    e.message
                );
            }

            return playlists;
        }

        public async Gee.List<Song> get_playlist_songs (
            string playlist_id
        ) {
            var songs =
                new Gee.ArrayList<Song> ();

            try {
                var items =
                    repository.get_items (playlist_id);

                foreach (var item in items) {
                    var song =
                        yield library_service.get_track (
                            item.song_id
                        );

                    if (song != null) {
                        songs.add (song);
                    }
                }
            } catch (Error e) {
                warning (
                    "Failed to get playlist songs '%s': %s",
                    playlist_id,
                    e.message
                );
            }

            return songs;
        }

        public async void create_playlist (
            string name
        ) {
            var playlist = new Playlist (
                Uuid.string_random (),
                name,
                0,
                0,
                null
            );

            try {
                repository.save_playlist (playlist);
            } catch (Error e) {
                warning (
                    "Failed to create playlist '%s': %s",
                    name,
                    e.message
                );
            }
        }

        public async void update_playlist (
            string playlist_id,
            string name,
            Collection<Song> songs
        ) {
            try {
                var playlist =
                    repository.get_playlist (
                        playlist_id
                    );

                if (playlist == null) {
                    warning (
                        "Cannot update playlist '%s': playlist not found",
                        playlist_id
                    );

                    return;
                }

                if (name == null) {
                    return;
                }

                var updated = new Playlist (
                    playlist.id,
                    name,
                    playlist.song_count,
                    playlist.duration,
                    playlist.cover_art
                );

                repository.save_playlist (updated);

                repository.clear_items (playlist.id);

                int index = 0;
                foreach (Song song in songs) {
                    var item = new PlaylistItem (
                        Uuid.string_random (),
                        playlist.id,
                        song.id,
                        index++
                    );

                    repository.add_item (item);
                }
            } catch (Error e) {
                warning (
                    "Failed to update playlist '%s': %s",
                    playlist_id,
                    e.message
                );
            }
        }

        public async void add_song_to_playlist (string playlist_id, Song song) {
            try {
                var songs = yield get_playlist_songs (playlist_id);
                songs.add (song);
                yield update_playlist (playlist_id, playlist_name (playlist_id), songs);
            } catch (Error e) {
                warning ("Failed to add song to playlist '%s': %s", playlist_id, e.message);
            }
        }

        private string playlist_name (string playlist_id) {
            try {
                var playlist = repository.get_playlist (playlist_id);
                return playlist != null ? playlist.name : "";
            } catch (Error e) {
                return "";
            }
        }

        public async void delete_playlist (
            string playlist_id
        ) {
            try {
                repository.delete_playlist (
                    playlist_id
                );
            } catch (Error e) {
                warning (
                    "Failed to delete playlist '%s': %s",
                    playlist_id,
                    e.message
                );
            }
        }
    }
}