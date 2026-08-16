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
using Gdk;

using PiPod.Components;
using PiPod.Models;

namespace PiPod.Views {
    public class BrowserView : BaseView {
        private ListBox artist_list;
        private ListBox album_list;
        private ListBox song_list;

        public signal void artist_selected (Artist artist);
        public signal void album_selected (Album album);
        public signal void song_selected (Song song);

        public BrowserView () {
            Object (orientation: Orientation.HORIZONTAL, spacing: 8);

            hexpand = true;
            vexpand = true;

            get_style_context ().add_class ("browse-box");

            build_ui ();
        }

        private void build_ui () {
            build_artist_list ();

            build_album_list ();

            build_song_list ();
        }

        private void build_artist_list () {
            Box box = create_list_column ("Artists", out artist_list);

            append (box);
        }

        private void build_album_list () {
            Box box = create_list_column ("Albums", out album_list);

            append (box);
        }

        private void build_song_list () {
            Box box = create_list_column ("Songs", out song_list);

            append (box);
        }

        private Box create_list_column (string title, out ListBox list) {
            Box box = new Box (Orientation.VERTICAL, 4);

            Label label = new Label (title);
            label.halign = Align.START;
            label.get_style_context ().add_class ("list-title");

            box.append (label);

            ScrolledWindow scroller = new ScrolledWindow ();

            scroller.hexpand = true;
            scroller.vexpand = true;
            scroller.get_style_context ().add_class ("list-scroller");

            list = new ListBox ();

            scroller.set_child (list);

            box.append (scroller);

            return box;
        }

        public void clear () {
            clear_artists ();
            clear_albums ();
            clear_songs ();
        }

        public void clear_artists () {
            clear_list (artist_list);
        }

        public void clear_albums () {
            clear_list (album_list);
        }

        public void clear_songs () {
            clear_list (song_list);
        }

        private void clear_list (ListBox list) {
            Widget? child = list.get_first_child ();

            while (child != null) {
                Widget? next = child.get_next_sibling ();

                list.remove (child);

                child = next;
            }
        }

        public void add_artist (Artist artist) {
            ArtistRow row = new ArtistRow (artist);
        
            row.selected.connect ((selected_artist) => artist_selected (selected_artist));
        
            artist_list.append (row);
        }
        
        public void add_album (Album album) {
            AlbumRow row = new AlbumRow (album);
        
            row.selected.connect ((selected_album) => album_selected (selected_album));
        
            album_list.append (row);
        }
        
        public void add_song (Song song) {
            SongRow row = new SongRow (song);
        
            row.selected.connect ((selected_song) => song_selected (selected_song));
        
            song_list.append (row);
        }

        public void show_artists (Artist[] artists) {
            clear_artists ();

            foreach (Artist artist in artists) {
                ArtistRow row = new ArtistRow (artist);

                row.selected.connect ((selected_artist) => artist_selected (selected_artist));

                artist_list.append (row);
            }
        }

        public void show_albums (Album[] albums) {
            clear_albums ();

            foreach (Album album in albums) {
                AlbumRow row = new AlbumRow (album);

                row.selected.connect ((selected_album) => album_selected (selected_album));

                album_list.append (row);
            }
        }

        public void show_songs (Song[] songs) {
            clear_songs ();

            foreach (Song song in songs) {
                SongRow row = new SongRow (song);

                row.selected.connect ((selected_song) => song_selected (selected_song));

                song_list.append (row);
            }
        }
    }
}