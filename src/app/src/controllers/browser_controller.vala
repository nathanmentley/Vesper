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

using Vesper.Core.Models;

using Vesper.Service.Libraries;
using Vesper.Service.Playlists;

using Vesper.App.Views;

namespace Vesper.App.Controllers {
    public class BrowserController : BaseController<BrowserView> {
        public signal void play_requested (Song song);

        private LibraryService library_service;
        private PlaylistService playlist_service;

        public BrowserController (
            LibraryService library_service,
            PlaylistService playlist_service,
            Gtk.Window parent_window
        ) {
            base (
                new BrowserView (parent_window)
            );

            this.library_service = library_service;
            this.playlist_service = playlist_service;

            connect_view ();
        }

        private void connect_view () {
            view.artist_selected.connect (
                artist => load_albums.begin (artist)
            );

            view.album_selected.connect (
                (artist, album) => load_album.begin (
                    artist,
                    album
                )
            );

            view.song_selected.connect (
                play_song
            );

            view.search_requested.connect (
                query => search.begin (query)
            );

            view.add_album_to_queue_requested.connect (
                (album, songs) => {
                    foreach (Song song in songs) {
                        play_requested (song);
                    }
                }
            );

            view.add_song_to_playlist_requested.connect (
                song => show_playlist_chooser.begin (song)
            );

            view.add_song_to_playlist_selected.connect (
                (song, playlist_id) => add_song_to_playlist.begin (song, playlist_id)
            );

            view.add_album_to_playlist_requested.connect (
                (album, songs) => show_songs_playlist_chooser.begin (songs)
            );

            view.add_songs_to_playlist_selected.connect (
                (songs, playlist_id) => add_songs_to_playlist.begin (songs, playlist_id)
            );
        }

        public async void load_artists () {
            view.show_browse ();

            Gee.List<Artist> artists =
                yield library_service.get_artists ();

            view.show_artists (
                artists.to_array ()
            );
        }

        private async void load_albums (
            Artist artist
        ) {
            view.clear_albums ();
            view.clear_songs ();

            Gee.List<Album> albums =
                yield library_service.get_albums (
                    artist.library_id,
                    artist.id
                );

            view.show_albums (
                artist,
                albums.to_array ()
            );
        }

        private async void load_album (
            Artist artist,
            Album album
        ) {
            view.clear_songs ();

            Gee.List<Song> songs =
                yield library_service.get_tracks (
                    artist.library_id,
                    artist.id,
                    album.id
                );

            view.show_songs (
                songs.to_array ()
            );
        }

        private async void search (
            string query
        ) {
            if (query.length == 0) {
                yield load_artists ();
                return;
            }

            Gee.List<SearchResult> results =
                library_service.search (
                    query
                );

            view.show_search_results (
                results
            );
        }

        private void play_song (
            Song song
        ) {
            if (song.stream_url == null) {
                warning (
                    "Cannot play song '%s': no stream URL",
                    song.title
                );

                return;
            }

            play_requested (
                song
            );
        }

        private async void show_playlist_chooser (Song song) {
            var playlists = yield playlist_service.get_playlists ();
            view.show_playlist_chooser (song, playlists);
        }

        private async void add_song_to_playlist (
            Song song,
            string playlist_id
        ) {
            yield playlist_service.add_song_to_playlist (playlist_id, song);
        }

        private async void show_songs_playlist_chooser (Song[] songs) {
            var playlists = yield playlist_service.get_playlists ();
            var song_list = new Gee.ArrayList<Song> ();
            song_list.add_all_array (songs);
            view.show_songs_playlist_chooser (song_list, playlists);
        }

        private async void add_songs_to_playlist (
            Gee.List<Song> songs,
            string playlist_id
        ) {
            foreach (Song song in songs) {
                yield playlist_service.add_song_to_playlist (playlist_id, song);
            }
        }
    }
}