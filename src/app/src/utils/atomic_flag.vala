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

namespace Vesper.App.Utils {
    public sealed class AtomicFlag : Object {
        private int _flag = 0; // 0 = false, 1 = true

        private bool flag {
            get {
                return AtomicInt.get(ref _flag) != 0;
            }
        }

        public bool current_value () {
            return this.flag;
        }

        public bool compare_and_exchange (bool old_val, bool new_val) {
            int old_int = convert (old_val);
            int new_int = convert (new_val);

            return AtomicInt.compare_and_exchange(ref _flag, old_int, new_int);
        }

        private int convert (bool value) {
            return value ? 1 : 0;
        }
    }
}