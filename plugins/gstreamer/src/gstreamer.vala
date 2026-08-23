/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

using GLib;
using Gst;

using PiPod.Core.Plugins;
using PiPod.Core.Settings;

using PiPod.Plugins.GStreamer;

namespace PiPod.Plugins.GStreamer {
    public sealed class GStreamerMusicEngine :
        GLib.Object,
        PiPod.Core.Plugins.Plugin,
        MusicEngine,
        SettingsProvider,
        ConfigurablePlugin {

        private Gst.Element? player = null;
        private Gst.Bus? bus = null;

        private double volume = 1.0;

        private PlaybackState playback_state =
            PlaybackState.STOPPED;

        private uint position_timer = 0;

        public string id { get { return "gstreamer-1"; } }

        public string source { get { return "Gstreamer"; } }

        public GStreamerMusicEngine () {
        }

        ~GStreamerMusicEngine () {
            stop_position_timer ();
            stop_bus ();

            if (player != null) {
                player.set_state (Gst.State.NULL);

                player = null;
            }
        }

        public void configure (SettingsEngine settings) {
            // GStreamer is initialized once when the plugin
            // module is registered.
        }

        public Gee.List<SettingDefinition> get_setting_definitions () {
            var settings = new Gee.ArrayList<SettingDefinition> ();

            settings.add (
                new SettingDefinition (
                    id,
                    "server-url",
                    "GStreamer Setting",
                    "GStreamer Setting that is a noop",
                    SettingType.STRING
                )
            );

            return settings;
        }

        public void set_source (string uri) {
            stop_player ();

            string escaped_uri = uri.replace ("\"", "\\\"");

            try {
                player = Gst.parse_launch ("playbin uri=\"" + escaped_uri + "\"");
            } catch (GLib.Error e) {
                warning ("Failed to create GStreamer player: %s", e.message);

                set_playback_state (PlaybackState.STOPPED);

                return;
            }

            if (player == null) {
                warning ("GStreamer failed to create playbin");

                return;
            }

            player.set_property ("volume", volume);

            bus = player.get_bus ();

            if (bus == null) {
                warning ("GStreamer player has no bus");

                player.set_state (Gst.State.NULL);

                player = null;

                return;
            }

            bus.add_signal_watch ();

            bus.message.connect ((_, gst_message) => handle_message (gst_message));

            start_position_timer ();
        }

        public bool has_player () {
            return player != null;
        }

        public PlaybackState get_state () {
            return playback_state;
        }

        public int64 get_position () {
            if (player == null) {
                return 0;
            }

            int64 position = 0;

            bool success = player.query_position (Gst.Format.TIME, out position);

            if (!success) {
                return 0;
            }

            return position;
        }

        public int64 get_duration () {
            if (player == null) {
                return 0;
            }

            int64 duration = 0;

            bool success = player.query_duration (Gst.Format.TIME, out duration);

            if (!success) {
                return 0;
            }

            return duration;
        }

        public void stop_player () {
            stop_position_timer ();
            stop_bus ();

            if (player != null) {
                player.set_state (Gst.State.NULL);

                player = null;
            }

            set_playback_state (PlaybackState.STOPPED);
        }

        public bool start_player () {
            if (player == null) {
                return false;
            }

            Gst.StateChangeReturn result = player.set_state (Gst.State.PLAYING);

            return result != Gst.StateChangeReturn.FAILURE;
        }

        public void pause_player () {
            if (player == null) {
                return;
            }

            player.set_state (Gst.State.PAUSED);
        }

        public void seek (int64 position) {
            if (player == null) {
                return;
            }

            bool success = player.seek_simple (
                Gst.Format.TIME,
                Gst.SeekFlags.FLUSH |
                Gst.SeekFlags.KEY_UNIT,
                position
            );

            if (!success) {
                warning ("GStreamer seek failed");
            }
        }

        public void set_volume (double volume) {
            this.volume = Math.fmin (1.0, Math.fmax (0.0, volume));

            if (player == null) {
                return;
            }

            player.set_property ("volume", this.volume);
        }

        public double get_volume () {
            return volume;
        }

        private void handle_message (Gst.Message gst_message) {
            GLib.message (
                "GStreamer message: %s from %s",
                gst_message.type.to_string (),
                gst_message.src.name
            );

            switch (gst_message.type) {
                case Gst.MessageType.EOS:
                    GLib.message ("GStreamer EOS received");

                    set_playback_state (PlaybackState.FINISHED);

                    break;

                case Gst.MessageType.ERROR:
                    handle_error (gst_message);

                    break;

                case Gst.MessageType.STATE_CHANGED:
                    handle_state_changed (gst_message);

                    break;

                default:
                    break;
            }
        }

        private void handle_error (Gst.Message gst_message) {
            GLib.Error error;
            string debug;

            gst_message.parse_error (out error, out debug);

            warning ("GStreamer error: %s", error.message);

            if (debug != null && debug != "") {
                warning ("GStreamer debug: %s", debug);
            }

            set_playback_state (PlaybackState.STOPPED);
        }

        private void handle_state_changed (Gst.Message gst_message) {
            if (player == null) {
                return;
            }

            if (gst_message.src != player) {
                return;
            }

            Gst.State old_state;
            Gst.State new_state;
            Gst.State pending_state;

            gst_message.parse_state_changed (out old_state, out new_state, out pending_state);

            switch (new_state) {
                case Gst.State.PLAYING:
                    set_playback_state (PlaybackState.PLAYING);

                    break;

                case Gst.State.PAUSED:
                    set_playback_state (PlaybackState.PAUSED);

                    break;

                case Gst.State.NULL:
                    set_playback_state (PlaybackState.STOPPED);

                    break;

                default:
                    break;
            }
        }

        private void set_playback_state (
            PlaybackState state
        ) {
            if (playback_state == state) {
                return;
            }

            GLib.message (
                "GStreamer playback state: %s -> %s",
                playback_state.to_string (),
                state.to_string ()
            );

            playback_state = state;

            this.state_changed (state);

            GLib.message ("state_changed emitted");
        }

        private void start_position_timer () {
            stop_position_timer ();

            position_timer = Timeout.add (250, update_position);
        }

        private void stop_position_timer () {
            if (position_timer == 0) {
                return;
            }

            Source.remove (position_timer);

            position_timer = 0;
        }

        private bool update_position() {
            if (player == null) {
                position_timer = 0;

                return Source.REMOVE;
            }

            int64 position = get_position ();
            int64 duration = get_duration ();

            this.position_changed (position, duration);

            return Source.CONTINUE;
        }

        private void stop_bus () {
            if (bus == null) {
                return;
            }

            bus.remove_signal_watch ();

            bus = null;
        }
    }
}

[ModuleInit]
public void peas_register_types (TypeModule module) {
    string[] items = {};
    unowned string[] args = items;

    Gst.init (ref args);

    Peas.ObjectModule object_module = module as Peas.ObjectModule;

    object_module.register_extension_type (typeof (MusicEngine), typeof (GStreamerMusicEngine));

    object_module.register_extension_type (typeof (SettingsProvider), typeof (GStreamerMusicEngine));
}