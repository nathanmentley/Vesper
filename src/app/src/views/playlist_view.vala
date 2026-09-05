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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
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
using Vesper.App.Models;
using Vesper.App.Utils;

namespace Vesper.App.Views {
    public class PlaylistView : BaseView {
        /*
         * -------------------------------------------------------------
         * Signals
         * -------------------------------------------------------------
         */

        public signal void selected ();

        public signal void change_playlist_request (Playlist playlist);

        public signal void create_playlist_request (string name);

        public signal void rename_playlist_request (Playlist playlist, string name);

        public signal void delete_playlist_request (Playlist playlist);

        /*
         * -------------------------------------------------------------
         * Playlist
         * -------------------------------------------------------------
         */

        private PlayQueue playlist;

        private ListBox song_list;

        private GLib.ListStore playlist_store;
        private DropDown playlist_dropdown;

        private Button menu_button;

        private Gtk.Stack content_stack;
        private Adw.StatusPage empty_page;

        /*
         * Currently selected Navidrome playlist.
         *
         * This is separate from the local playback Playlist model.
         */
        private Playlist? selected_playlist = null;

        public PlaylistView (PlayQueue playlist, Gtk.Window parent_window) {
            base (parent_window);

            this.playlist = playlist;

            build_ui ();
            connect_signals ();
        }

        /*
         * =============================================================
         * UI
         * =============================================================
         */

        private void build_ui () {
            /*
             * ---------------------------------------------------------
             * Playlist model
             * ---------------------------------------------------------
             */

            playlist_store =
                new GLib.ListStore (
                    typeof (Playlist)
                );

            var expression =
                new PropertyExpression (
                    typeof (Playlist),
                    null,
                    "name"
                );

            playlist_dropdown =
                new DropDown (
                    playlist_store,
                    expression
                );

            playlist_dropdown.hexpand = true;

            /*
             * ---------------------------------------------------------
             * Playlist selector
             * ---------------------------------------------------------
             *
             *             [ My Playlist ▼ ] [ ⋮ ]
             *
             * No "Playlist" label is necessary. The dropdown's
             * selected value provides the context.
             * ---------------------------------------------------------
             */

            var playlist_row =
                new Gtk.Box (
                    Orientation.HORIZONTAL,
                    6
                );

            playlist_row.hexpand = true;

            playlist_row.append (
                playlist_dropdown
            );

            /*
             * ---------------------------------------------------------
             * Playlist menu
             * ---------------------------------------------------------
             */

            menu_button =
                new Button ();

            menu_button.icon_name =
                "view-more-symbolic";

            menu_button.tooltip_text =
                "Playlist options";

            menu_button.add_css_class (
                "flat"
            );

            playlist_row.append (
                menu_button
            );

            /*
             * ---------------------------------------------------------
             * Song list
             * ---------------------------------------------------------
             */

            song_list =
                new ListBox ();

            song_list.selection_mode =
                SelectionMode.NONE;

            song_list.show_separators =
                true;

            song_list.add_css_class (
                "boxed-list"
            );

            /*
             * ---------------------------------------------------------
             * Scroller
             * ---------------------------------------------------------
             */

            var song_scroller =
                new ScrolledWindow ();

            song_scroller.hscrollbar_policy =
                PolicyType.NEVER;

            song_scroller.vscrollbar_policy =
                PolicyType.AUTOMATIC;

            song_scroller.vexpand = true;
            song_scroller.hexpand = true;

            song_scroller.set_child (
                song_list
            );

            /*
             * ---------------------------------------------------------
             * Empty state
             * ---------------------------------------------------------
             */

            empty_page =
                new Adw.StatusPage ();

            empty_page.vexpand = true;

            empty_page.icon_name =
                "audio-x-generic-symbolic";

            empty_page.title =
                "Playlist is empty";

            empty_page.description =
                "Add songs from your library to build a playlist.";

            /*
             * ---------------------------------------------------------
             * Content stack
             * ---------------------------------------------------------
             */

            content_stack =
                new Gtk.Stack ();

            content_stack.vexpand = true;
            content_stack.hexpand = true;

            content_stack.add_named (
                empty_page,
                "empty"
            );

            content_stack.add_named (
                song_scroller,
                "songs"
            );

            /*
             * ---------------------------------------------------------
             * Main content
             * ---------------------------------------------------------
             */

            var content =
                new Gtk.Box (
                    Orientation.VERTICAL,
                    18
                );

            content.hexpand = true;
            content.vexpand = true;

            content.append (
                playlist_row
            );

            content.append (
                content_stack
            );

            /*
             * ---------------------------------------------------------
             * Clamp
             * ---------------------------------------------------------
             */

            var clamp =
                new Adw.Clamp ();

            clamp.maximum_size =
                900;

            clamp.tightening_threshold =
                700;

            clamp.set_margin_top (
                12
            );

            clamp.set_margin_bottom (
                12
            );

            clamp.set_margin_start (
                12
            );

            clamp.set_margin_end (
                12
            );

            clamp.vexpand = true;
            clamp.hexpand = true;

            clamp.set_child (
                content
            );

            append (
                clamp
            );
        }

        /*
         * =============================================================
         * Signals
         * =============================================================
         */

        private void connect_signals () {
            /*
             * ---------------------------------------------------------
             * Playlist selection
             * ---------------------------------------------------------
             */

            playlist_dropdown.notify["selected"].connect (() => {
                Playlist? selected_obj =
                    playlist_dropdown.selected_item
                        as Playlist;

                if (selected_obj == null) {
                    return;
                }

                selected_playlist =
                    selected_obj;

                change_playlist_request (
                    selected_obj
                );
            });

            /*
             * ---------------------------------------------------------
             * Playlist menu
             * ---------------------------------------------------------
             */

            menu_button.clicked.connect (() => {
                show_playlist_menu ();
            });
        }

        /*
         * =============================================================
         * Playlist menu
         * =============================================================
         */

private void show_playlist_menu () {
    var popover =
        new Gtk.Popover ();

    popover.has_arrow = true;

    var box =
        new Gtk.Box (
            Orientation.VERTICAL,
            0
        );

    box.margin_top = 6;
    box.margin_bottom = 6;
    box.margin_start = 6;
    box.margin_end = 6;

    /*
     * -------------------------------------------------------------
     * New Playlist
     * -------------------------------------------------------------
     */

    var new_button =
        new Button.with_label (
            "New Playlist"
        );

    new_button.halign =
        Align.FILL;

    new_button.add_css_class (
        "flat"
    );

    new_button.clicked.connect (() => {
        popover.popdown ();
        show_create_dialog ();
    });

    box.append (
        new_button
    );

    /*
     * -------------------------------------------------------------
     * Rename Playlist
     * -------------------------------------------------------------
     */

    if (selected_playlist != null) {
        var rename_button =
            new Button.with_label (
                "Rename Playlist"
            );

        rename_button.halign =
            Align.FILL;

        rename_button.add_css_class (
            "flat"
        );

        rename_button.clicked.connect (() => {
            popover.popdown ();

            if (selected_playlist != null) {
                show_rename_dialog (
                    selected_playlist
                );
            }
        });

        box.append (
            rename_button
        );

        /*
         * ---------------------------------------------------------
         * Delete Playlist
         * ---------------------------------------------------------
         */

        var delete_button =
            new Button.with_label (
                "Delete Playlist"
            );

        delete_button.halign =
            Align.FILL;

        delete_button.add_css_class (
            "flat"
        );

        delete_button.add_css_class (
            "destructive-action"
        );

        delete_button.clicked.connect (() => {
            popover.popdown ();

            if (selected_playlist != null) {
                show_delete_dialog (
                    selected_playlist
                );
            }
        });

        box.append (
            delete_button
        );
    }

    popover.set_child (
        box
    );

    popover.set_parent (
        menu_button
    );

    popover.popup ();
}

        /*
         * =============================================================
         * Create playlist
         * =============================================================
         */

        private void show_create_dialog () {
            var entry =
                new Entry ();

            entry.placeholder_text =
                "Playlist name";

            entry.activates_default = true;

            var dialog =
                new Adw.AlertDialog (
                    "Create Playlist",
                    "Give your new playlist a name."
                );

            dialog.set_extra_child (
                entry
            );

            dialog.add_response (
                "cancel",
                "Cancel"
            );

            dialog.add_response (
                "create",
                "Create"
            );

            dialog.set_default_response (
                "create"
            );

            dialog.set_close_response (
                "cancel"
            );

            dialog.set_response_appearance (
                "create",
                Adw.ResponseAppearance.SUGGESTED
            );

            dialog.response.connect ((response) => {
                if (response != "create") {
                    return;
                }

                string name =
                    entry.text.strip ();

                if (name.length == 0) {
                    return;
                }

                create_playlist_request (
                    name
                );
            });

            dialog.present (
                get_root () as Gtk.Widget
            );
        }

        /*
         * =============================================================
         * Rename playlist
         * =============================================================
         */

        private void show_rename_dialog (
            Playlist playlist
        ) {
            var entry =
                new Entry ();

            entry.text =
                playlist.name;

            entry.activates_default =
                true;

            entry.select_region (
                0,
                -1
            );

            var dialog =
                new Adw.AlertDialog (
                    "Rename Playlist",
                    null
                );

            dialog.set_extra_child (
                entry
            );

            dialog.add_response (
                "cancel",
                "Cancel"
            );

            dialog.add_response (
                "rename",
                "Rename"
            );

            dialog.set_default_response (
                "rename"
            );

            dialog.set_close_response (
                "cancel"
            );

            dialog.set_response_appearance (
                "rename",
                Adw.ResponseAppearance.SUGGESTED
            );

            dialog.response.connect ((response) => {
                if (response != "rename") {
                    return;
                }

                string name =
                    entry.text.strip ();

                if (name.length == 0) {
                    return;
                }

                rename_playlist_request (
                    playlist,
                    name
                );
            });

            dialog.present (
                get_root () as Gtk.Widget
            );
        }

        /*
         * =============================================================
         * Delete playlist
         * =============================================================
         */

        private void show_delete_dialog (
            Playlist playlist
        ) {
            var dialog =
                new Adw.AlertDialog (
                    "Delete Playlist?",
                    @"Are you sure you want to delete \"$(playlist.name)\"?"
                );

            dialog.add_response (
                "cancel",
                "Cancel"
            );

            dialog.add_response (
                "delete",
                "Delete"
            );

            dialog.set_close_response (
                "cancel"
            );

            dialog.set_response_appearance (
                "delete",
                Adw.ResponseAppearance.DESTRUCTIVE
            );

            dialog.response.connect ((response) => {
                if (response != "delete") {
                    return;
                }

                delete_playlist_request (
                    playlist
                );
            });

            dialog.present (
                get_root () as Gtk.Widget
            );
        }

        /*
         * =============================================================
         * Playlist dropdown
         * =============================================================
         */

        public void clear_playlist_dropdown () {
            selected_playlist = null;

            playlist_store.remove_all ();
        }

        public void add_playlist_to_dropdown (
            Playlist playlist
        ) {
            playlist_store.append (playlist);
        }

        /*
         * =============================================================
         * Rebuild playlist
         * =============================================================
         */

        public void rebuild () {
            clear_list (
                song_list
            );

            Collection<Song> songs =
                playlist.get_songs ();

            int current_index =
                playlist.get_current_index ();

            int playlist_length =
                songs.size;

            int counter = 0;

            foreach (Song song in songs) {
                PlaylistEntry entry =
                    new PlaylistEntry (
                        song,
                        counter,
                        counter == current_index,
                        playlist_length
                    );

                /*
                 * Select song.
                 */

                entry.selected.connect (
                    index => {
                        playlist.set_current_index (
                            index
                        );

                        selected ();

                        rebuild ();
                    }
                );

                /*
                 * Move up.
                 */

                entry.move_up_request.connect (
                    index => {
                        playlist.move_song (
                            index,
                            index - 1
                        );

                        rebuild ();
                    }
                );

                /*
                 * Move down.
                 */

                entry.move_down_request.connect (
                    index => {
                        playlist.move_song (
                            index,
                            index + 1
                        );

                        rebuild ();
                    }
                );

                /*
                 * Delete.
                 */

                entry.delete_request.connect (
                    index => {
                        playlist.delete_song (
                            index
                        );

                        rebuild ();
                    }
                );

                song_list.append (
                    entry
                );

                counter++;
            }

            /*
             * Empty state.
             */

            if (playlist_length == 0) {
                content_stack.visible_child_name =
                    "empty";
            } else {
                content_stack.visible_child_name =
                    "songs";
            }
        }

        /*
         * =============================================================
         * Clear ListBox
         * =============================================================
         */

        private void clear_list (
            ListBox list
        ) {
            Widget? child =
                list.get_first_child ();

            while (child != null) {
                Widget? next =
                    child.get_next_sibling ();

                list.remove (
                    child
                );

                child = next;
            }
        }
    }
}