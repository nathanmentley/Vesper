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
using Vesper.Service.UserState;

namespace Vesper.Service.Mixes {
    public sealed class MixServiceImpl : MixService, Object {
        private LibraryService library_service;
        private UserStateService user_state_service;

        public MixServiceImpl (
            LibraryService library_service,
            UserStateService user_state_service
        ) {
            this.library_service = library_service;
            this.user_state_service = user_state_service;
        }

        public async Gee.List<Song> get_mix_songs (
            MixType type,
            int limit = 100
        ) throws Error {
            switch (type) {
                case MixType.FAVORITES:
                    return yield user_state_service.get_favorites (); 
                case MixType.RECENTLY_PLAYED:
                    return yield user_state_service.get_recently_played_songs (limit);
                case MixType.RECENTLY_ADDED:
                    return yield library_service.get_recently_added (limit);
                case MixType.MOST_PLAYED:
                    return yield user_state_service.get_most_played (limit);
                case MixType.NEVER_PLAYED:
                    return yield user_state_service.get_never_played (limit);
                default:
                    return new Gee.ArrayList<Song> ();
            }
        }
    }
}
