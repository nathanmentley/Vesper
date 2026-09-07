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
using Gtk;
using Adw;

using Vesper.Core.Models;
using Vesper.App.Components;
using Vesper.App.Views;

namespace Vesper.App.Views {
    public class PlaylistView : BaseView {
        public signal void mix_selected (Mix mix);
        public signal void playlist_selected (Playlist playlist);
        public signal void play_requested (Gee.List<Song> songs);
        public signal void shuffle_requested (Gee.List<Song> songs);
        public signal void create_playlist_request (string name);
        public signal void rename_playlist_request (
            Playlist playlist,
            string name
        );
        public signal void delete_playlist_request (Playlist playlist);
        public signal void playlist_songs_changed (
            Playlist playlist,
            Gee.List<Song> songs
        );

        private Gtk.Stack stack;
        private ListBox landing_list;
        private ListBox song_list;

        private Button detail_play_button;
        private Button detail_shuffle_button;
        private Button detail_menu_button;

        private Label detail_title;
        private Label detail_count;

        private Playlist? selected_playlist;

        private Gee.List<Song> detail_songs =
            new ArrayList<Song> ();

        private Gee.List<Mix> mixes;

        public PlaylistView (Gtk.Window parent_window, Gee.List<Mix> mixes) {
            base (parent_window);

            this.mixes = mixes;

            build_ui ();
        }

        public void set_mixes (Gee.List<Mix> mixes) {
            this.mixes = mixes;

            Widget landing = build_landing ();
            stack.remove (stack.get_child_by_name ("landing"));
            stack.add_named (landing, "landing");
        }

        private void build_ui () {
            stack = new Gtk.Stack ();
            stack.hexpand = true;
            stack.vexpand = true;

            stack.add_named (
                build_landing (),
                "landing"
            );

            stack.add_named (
                build_detail (),
                "detail"
            );

            append (stack);
        }

        private Widget build_landing () {
            var content = new Box (
                Orientation.VERTICAL,
                0
            );

            content.set_margin_top (24);
            content.set_margin_bottom (24);
            content.set_margin_start (24);
            content.set_margin_end (24);

            /*
             * Page header
             */
            var header = new Box (
                Orientation.HORIZONTAL,
                12
            );

            var title_box = new Box (
                Orientation.VERTICAL,
                2
            );

            var title = new Label ("Playlists");
            title.halign = Align.START;
            title.add_css_class ("title-1");

            var subtitle = new Label (
                "Your playlists and personalized mixes"
            );

            subtitle.halign = Align.START;
            subtitle.add_css_class ("dim-label");

            title_box.append (title);
            title_box.append (subtitle);

            header.append (title_box);

            var spacer = new Box (
                Orientation.HORIZONTAL,
                0
            );

            spacer.hexpand = true;
            header.append (spacer);

            var new_button = new Button.from_icon_name (
                "list-add-symbolic"
            );

            new_button.tooltip_text = "New Playlist";
            new_button.add_css_class ("suggested-action");

            new_button.clicked.connect (
                show_create_dialog
            );

            header.append (new_button);

            content.append (header);

            /*
             * Main scrolling content
             */
            var scroller = new ScrolledWindow ();
            scroller.vexpand = true;
            scroller.hexpand = true;

            var sections = new Box (
                Orientation.VERTICAL,
                24
            );

            sections.set_margin_top (24);

            /*
             * Mixes
             */
            var mixes_box = new Box (
                Orientation.VERTICAL,
                10
            );

            var mixes_title = new Label ("Mixes");
            mixes_title.halign = Align.START;
            mixes_title.add_css_class ("title-3");

            mixes_box.append (mixes_title);

            /*
             * FlowBox automatically wraps the mix cards as the
             * available width changes.
             */
            var mixes_flow = new FlowBox ();

            mixes_flow.selection_mode =
                SelectionMode.NONE;

            mixes_flow.homogeneous = true;
            mixes_flow.row_spacing = 12;
            mixes_flow.column_spacing = 12;
            mixes_flow.hexpand = true;

            foreach (Mix mix in mixes) {
                add_mix_card (mixes_flow, mix);
            }

            mixes_box.append (mixes_flow);
            sections.append (mixes_box);

            /*
             * User playlists
             */
            var playlists_box = new Box (
                Orientation.VERTICAL,
                10
            );

            var playlists_header = new Box (
                Orientation.HORIZONTAL,
                8
            );

            var playlists_title = new Label (
                "Your Playlists"
            );

            playlists_title.halign = Align.START;
            playlists_title.add_css_class ("title-3");
            playlists_title.hexpand = true;

            playlists_header.append (playlists_title);

            var create_button = new Button.with_label (
                "New Playlist"
            );

            create_button.add_css_class ("flat");

            create_button.clicked.connect (
                show_create_dialog
            );

            playlists_header.append (create_button);

            playlists_box.append (playlists_header);

            landing_list = new ListBox ();

            landing_list.selection_mode =
                SelectionMode.NONE;

            landing_list.show_separators = false;
            landing_list.add_css_class ("boxed-list");

            playlists_box.append (landing_list);

            sections.append (playlists_box);

            scroller.set_child (sections);
            content.append (scroller);

            return content;
        }

        private void add_mix_card (FlowBox flow, Mix mix) {
            var button = new Button ();

            /*
             * This gives FlowBox a useful minimum width. As the
             * available space decreases, cards wrap instead of
             * becoming absurdly narrow.
             */
            button.set_size_request (
                240,
                -1
            );

            button.hexpand = true;

            button.add_css_class ("card");
            button.add_css_class ("flat");

            var content = new Box (
                Orientation.HORIZONTAL,
                12
            );

            content.set_margin_top (16);
            content.set_margin_bottom (16);
            content.set_margin_start (16);
            content.set_margin_end (16);

            var icon = new Image.from_icon_name (mix.icon);

            icon.pixel_size = 32;
            icon.valign = Align.CENTER;

            content.append (icon);

            var text = new Box (
                Orientation.VERTICAL,
                2
            );

            text.valign = Align.CENTER;
            text.hexpand = true;

            var title = new Label (mix.name);
            title.halign = Align.START;
            title.ellipsize =
                Pango.EllipsizeMode.END;

            title.add_css_class ("heading");

            var subtitle = new Label (
                mix.description
            );

            subtitle.halign = Align.START;
            subtitle.ellipsize =
                Pango.EllipsizeMode.END;

            subtitle.add_css_class ("dim-label");

            text.append (title);
            text.append (subtitle);

            content.append (text);

            var arrow = new Image.from_icon_name (
                "go-next-symbolic"
            );

            arrow.valign = Align.CENTER;
            arrow.add_css_class ("dim-label");

            content.append (arrow);

            button.set_child (content);

            button.clicked.connect (() => {
                mix_selected (mix);
            });

            var child = new FlowBoxChild ();
            child.set_child (button);

            flow.append (child);
        }

        private Widget build_detail () {
            var content = new Box (
                Orientation.VERTICAL,
                12
            );

            content.set_margin_top (12);
            content.set_margin_bottom (12);
            content.set_margin_start (12);
            content.set_margin_end (12);

            var header = new Box (
                Orientation.HORIZONTAL,
                8
            );

            var back = new Button.from_icon_name (
                "go-previous-symbolic"
            );

            back.tooltip_text =
                "Back to playlists";

            back.add_css_class ("flat");

            back.clicked.connect (() => {
                stack.visible_child_name =
                    "landing";
            });

            header.append (back);

            detail_title = new Label ("");
            detail_title.halign = Align.START;
            detail_title.hexpand = true;
            detail_title.add_css_class ("title-2");

            header.append (detail_title);

            detail_count = new Label ("");
            detail_count.add_css_class ("dim-label");

            header.append (detail_count);

            detail_menu_button =
                new Button.from_icon_name (
                    "view-more-symbolic"
                );

            detail_menu_button.tooltip_text =
                "Playlist options";

            detail_menu_button.add_css_class ("flat");

            detail_menu_button.clicked.connect (
                show_playlist_menu
            );

            header.append (detail_menu_button);

            content.append (header);

            var actions = new Box (
                Orientation.HORIZONTAL,
                8
            );

            detail_play_button =
                new Button.with_label ("Play");

            detail_play_button.clicked.connect (() => {
                play_requested (
                    new ArrayList<Song>.wrap (
                        detail_songs.to_array ()
                    )
                );
            });

            detail_shuffle_button =
                new Button.with_label ("Shuffle");

            detail_shuffle_button.clicked.connect (() => {
                shuffle_requested (
                    new ArrayList<Song>.wrap (
                        detail_songs.to_array ()
                    )
                );
            });

            actions.append (detail_play_button);
            actions.append (detail_shuffle_button);

            content.append (actions);

            song_list = new ListBox ();

            song_list.selection_mode =
                SelectionMode.NONE;

            song_list.show_separators = true;
            song_list.add_css_class ("boxed-list");

            var scroller = new ScrolledWindow ();
            scroller.vexpand = true;
            scroller.set_child (song_list);

            content.append (scroller);

            return content;
        }

        public void show_landing (
            Gee.List<Playlist> playlists
        ) {
            clear_list (landing_list);

            foreach (Playlist playlist in playlists) {
                var row = new ActionRow ();

                row.title = playlist.name;

                row.subtitle =
                    "%d songs".printf (
                        playlist.song_count
                    );

                row.activatable = true;

                var icon = new Image.from_icon_name (
                    "audio-x-generic-symbolic"
                );

                icon.valign = Align.CENTER;

                row.add_prefix (icon);

                var arrow = new Image.from_icon_name (
                    "go-next-symbolic"
                );

                arrow.add_css_class ("dim-label");

                row.add_suffix (arrow);

                row.activated.connect (() => {
                    playlist_selected (playlist);
                });

                landing_list.append (row);
            }

            stack.visible_child_name =
                "landing";
        }

        public void show_detail (
            string title,
            Gee.List<Song> songs,
            bool editable,
            Playlist? playlist
        ) {
            selected_playlist = playlist;

            detail_songs.clear ();

            foreach (Song song in songs) {
                detail_songs.add (song);
            }

            render_detail (
                title,
                editable,
                playlist
            );

            stack.visible_child_name =
                "detail";
        }

        private void render_detail (
            string title,
            bool editable,
            Playlist? playlist
        ) {
            detail_title.set_text (title);

            detail_count.set_text (
                "%d songs".printf (
                    detail_songs.size
                )
            );

            detail_menu_button.visible =
                editable;

            clear_list (song_list);

            int index = 0;

            foreach (Song song in detail_songs) {
                if (editable && playlist != null) {
                    var entry = new PlaylistEntry (
                        song,
                        index,
                        false,
                        detail_songs.size,
                        true
                    );

                    entry.move_up_request.connect (
                        index => move_song (
                            index,
                            -1
                        )
                    );

                    entry.move_down_request.connect (
                        index => move_song (
                            index,
                            1
                        )
                    );

                    entry.delete_request.connect (
                        remove_song
                    );

                    song_list.append (entry);
                } else {
                    var row = new ActionRow ();

                    row.title = song.title;
                    row.subtitle = "%s - %s".printf (
                        song.artist.name,
                        song.album.name
                    );

                    row.activatable = true;

                    row.activated.connect (() => {
                        play_requested (
                            new ArrayList<Song>.wrap (
                                { song }
                            )
                        );
                    });

                    song_list.append (row);
                }

                index++;
            }

            detail_play_button.sensitive =
                detail_songs.size > 0;

            detail_shuffle_button.sensitive =
                detail_songs.size > 0;
        }

        private void move_song (
            int index,
            int offset
        ) {
            int target = index + offset;

            if (index < 0 ||
                index >= detail_songs.size ||
                target < 0 ||
                target >= detail_songs.size) {
                return;
            }

            Song song = detail_songs[index];

            detail_songs.remove_at (index);

            detail_songs.insert (
                target,
                song
            );

            rebuild_detail ();

            if (selected_playlist != null) {
                playlist_songs_changed (
                    selected_playlist,
                    detail_songs
                );
            }
        }

        private void remove_song (
            int index
        ) {
            if (index < 0 ||
                index >= detail_songs.size) {
                return;
            }

            detail_songs.remove_at (index);

            rebuild_detail ();

            if (selected_playlist != null) {
                playlist_songs_changed (
                    selected_playlist,
                    detail_songs
                );
            }
        }

        private void rebuild_detail () {
            if (selected_playlist == null) {
                return;
            }

            render_detail (
                selected_playlist.name,
                true,
                selected_playlist
            );
        }

        private void show_playlist_menu () {
            if (selected_playlist == null) {
                return;
            }

            var playlist = selected_playlist;

            var popover = new Popover ();

            var box = new Box (
                Orientation.VERTICAL,
                0
            );

            var rename = new Button.with_label (
                "Rename Playlist"
            );

            rename.add_css_class ("flat");

            rename.clicked.connect (() => {
                popover.popdown ();
                show_rename_dialog (
                    playlist
                );
            });

            var delete = new Button.with_label (
                "Delete Playlist"
            );

            delete.add_css_class ("flat");
            delete.add_css_class (
                "destructive-action"
            );

            delete.clicked.connect (() => {
                popover.popdown ();
                delete_playlist_request (
                    playlist
                );
            });

            box.append (rename);
            box.append (delete);

            popover.set_child (box);
            popover.set_parent (
                detail_menu_button
            );
            popover.popup ();
        }

        private void show_create_dialog () {
            var entry = new Entry ();

            var dialog = new Adw.AlertDialog (
                "Create Playlist",
                "Give your new playlist a name."
            );

            dialog.set_extra_child (entry);

            dialog.add_response (
                "cancel",
                "Cancel"
            );

            dialog.add_response (
                "create",
                "Create"
            );

            dialog.response.connect (
                response => {
                    if (response == "create" &&
                        entry.text.strip () != "") {
                        create_playlist_request (
                            entry.text.strip ()
                        );
                    }
                }
            );

            dialog.present (
                get_root () as Widget
            );
        }

        private void show_rename_dialog (
            Playlist playlist
        ) {
            var entry = new Entry ();
            entry.text = playlist.name;

            var dialog = new Adw.AlertDialog (
                "Rename Playlist",
                null
            );

            dialog.set_extra_child (entry);

            dialog.add_response (
                "cancel",
                "Cancel"
            );

            dialog.add_response (
                "rename",
                "Rename"
            );

            dialog.response.connect (
                response => {
                    if (response == "rename" &&
                        entry.text.strip () != "") {
                        rename_playlist_request (
                            playlist,
                            entry.text.strip ()
                        );
                    }
                }
            );

            dialog.present (
                get_root () as Widget
            );
        }

        public void show_error (
            string message
        ) {
            warning (
                "Playlist error: %s",
                message
            );
        }

        private void clear_list (
            ListBox list
        ) {
            Widget? child =
                list.get_first_child ();

            while (child != null) {
                Widget? next =
                    child.get_next_sibling ();

                list.remove (child);

                child = next;
            }
        }
    }
}