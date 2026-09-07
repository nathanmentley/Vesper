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

using Vesper.Core.Plugins;

namespace Vesper.Service.Media {
    public interface MediaService : Object {
        public abstract void set_source (string uri);

        public abstract bool has_player ();

        public abstract PlaybackState get_state ();

        public abstract int64 get_position ();

        public abstract int64 get_duration ();

        public abstract void stop_player ();
        public abstract bool start_player ();
        public abstract void pause_player ();

        public abstract void seek (int64 position);

        public abstract void set_volume (double volume);
        public abstract double get_volume ();

        public signal void state_changed (
            PlaybackState state
        );

        public signal void position_changed (
            int64 position,
            int64 duration
        );
    }
}