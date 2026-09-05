/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

using Vesper.Core.Plugins;

namespace Vesper.Service.Media {
    public sealed class MediaServiceImpl : MediaService, Object {
        private MusicEngine music_engine;

        public MediaServiceImpl (MusicEngine music_engine) {
            this.music_engine = music_engine;

            connect_signals ();
        }

        private void connect_signals () {
            music_engine.state_changed.connect ((state) => state_changed.emit (state));
            music_engine.position_changed.connect ((position, duration) => position_changed.emit (position, duration));
        }

        public void set_source (string uri) {
            music_engine.set_source (uri);
        }

        public bool has_player () {
            return music_engine.has_player ();
        }

        public PlaybackState get_state() {
            return music_engine.get_state ();
        }

        public int64 get_position () {
            return music_engine.get_position ();
        }

        public int64 get_duration () {
            return music_engine.get_duration ();
        }

        public void stop_player () {
            music_engine.stop_player ();
        }

        public bool start_player () {
            return music_engine.start_player ();
        }

        public void pause_player () {
            music_engine.pause_player ();
        }

        public void seek (int64 position) {
            music_engine.seek (position);
        }

        public void set_volume (double volume) {
            music_engine.set_volume (volume);
        }

        public double get_volume () {
            return music_engine.get_volume ();
        }
    }
}