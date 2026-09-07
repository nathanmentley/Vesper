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
        private sealed class FavoritesMixKind : MixKind, Object {}
        private sealed class RecentlyPlayedMixKind : MixKind, Object {}
        private sealed class RecentlyAddedMixKind : MixKind, Object {}
        private sealed class MostPlayedMixKind : MixKind, Object {}
        private sealed class NeverPlayedMixKind : MixKind, Object {}

        private sealed class ArtistMixKind : MixKind, Object {
            public string artist_id { get; construct; }

            public ArtistMixKind (string artist_id) {
                Object (artist_id: artist_id);
            }
        }

        private const int ARTIST_MIX_COUNT = 4;
        private const int SIMILAR_ARTIST_COUNT = 8;

        private LibraryService library_service;
        private UserStateService user_state_service;

        public MixServiceImpl (
            LibraryService library_service,
            UserStateService user_state_service
        ) {
            this.library_service = library_service;
            this.user_state_service = user_state_service;
        }

        public async Gee.List<Mix> get_mixes () throws Error {
            Gee.List<Mix> result = new ArrayList<Mix>();

            result.add(
                new Mix(
                    new FavoritesMixKind (),
                    "Favorites",
                    "Songs you've saved",
                    "starred-symbolic"
                )
            );

            result.add(
                new Mix(
                    new RecentlyPlayedMixKind (),
                    "Recently Played",
                    "Songs you've listened to lately",
                    "document-open-recent-symbolic"
                )
            );

            result.add(
                new Mix(
                    new RecentlyAddedMixKind (),
                    "Recently Added",
                    "New additions to your library",
                    "list-add-symbolic"
                )
            );

            result.add(
                new Mix(
                    new MostPlayedMixKind (),
                    "Most Played",
                    "Your most played songs",
                    "media-playlist-shuffle-symbolic"
                )
            );

            result.add(
                new Mix(
                    new NeverPlayedMixKind (),
                    "Never Played",
                    "Songs waiting to be discovered",
                    "media-playlist-symbolic"
                )
            );

            Gee.List<Artist> artists = yield get_top_artists (ARTIST_MIX_COUNT);

            foreach (Artist artist in artists) {
                result.add (
                    new Mix (
                        new ArtistMixKind (artist.id),
                        "%s Mix".printf (artist.name),
                        "%s and similar artists".printf (artist.name),
                        "media-playlist-symbolic"
                    )
                );
            }

            return result;
        }

        public async Gee.List<Song> get_mix_songs (Mix mix, int limit = 100) throws Error {
            if (mix.kind is FavoritesMixKind) {
                return yield user_state_service.get_favorites (); 
            } else if (mix.kind is RecentlyPlayedMixKind) {
                return yield user_state_service.get_recently_played_songs (limit);
            } else if (mix.kind is RecentlyAddedMixKind) {
                return yield library_service.get_recently_added (limit);
            } else if (mix.kind is MostPlayedMixKind) {
                return yield user_state_service.get_most_played (limit);
            } else if (mix.kind is NeverPlayedMixKind) {
                return yield user_state_service.get_never_played (limit);
            } else if (mix.kind is ArtistMixKind) {
                if (limit <= 0) {
                    return new ArrayList<Song> ();
                }

                ArtistMixKind artist_kind = (ArtistMixKind) mix.kind;
                Gee.List<Artist> artists = yield library_service.get_artists ();
                Artist? seed = find_artist (artists, artist_kind.artist_id);

                if (seed == null) {
                    return new ArrayList<Song> ();
                }

                Gee.List<Artist> selected_artists =
                    yield select_similar_artists (seed, artists);
                Gee.List<Song> results = new ArrayList<Song> ();
                var song_ids = new HashSet<string> ();

                foreach (Artist artist in selected_artists) {
                    Gee.List<Album> albums =
                        yield library_service.get_albums (null, artist.id);

                    foreach (Album album in albums) {
                        Gee.List<Song> songs =
                            yield library_service.get_tracks (null, artist.id, album.id);

                        foreach (Song song in songs) {
                            if (song_ids.add (song.id)) {
                                results.add (song);
                            }
                        }
                    }
                }

                shuffle (results);

                while (results.size > limit) {
                    results.remove_at (results.size - 1);
                }

                return results;
            }

            return new Gee.ArrayList<Song> ();
        }

        private async Gee.List<Artist> select_similar_artists (
            Artist seed,
            Gee.List<Artist> artists
        ) throws Error {
            Gee.List<Artist> selected = new ArrayList<Artist> ();
            selected.add (seed);
            Gee.List<Genre> seed_genres = yield get_artist_genres (seed);

            Gee.List<Artist> similar = new ArrayList<Artist> ();
            var similar_ids = new HashSet<string> ();

            while (similar.size < SIMILAR_ARTIST_COUNT) {
                Artist? best_match = null;
                int best_score = 0;

                foreach (Artist candidate in artists) {
                    if (candidate.id == seed.id || similar_ids.contains (candidate.id)) {
                        continue;
                    }

                    Gee.List<Genre> candidate_genres =
                        yield get_artist_genres (candidate);
                    int score = shared_genres (seed_genres, candidate_genres);

                    if (best_match == null || score > best_score) {
                        best_score = score;
                        best_match = candidate;
                    }
                }

                if (best_match == null) {
                    break;
                }

                similar.add (best_match);
                similar_ids.add (best_match.id);
            }

            selected.add_all (similar);
            return selected;
        }

        private async Gee.List<Genre> get_artist_genres (Artist artist) throws Error {
            var genres = new ArrayList<Genre> ();
            var genre_ids = new HashSet<string> ();
            Gee.List<Album> albums =
                yield library_service.get_albums (null, artist.id);

            foreach (Album album in albums) {
                foreach (Genre genre in album.genres) {
                    if (genre_ids.add (genre.id)) {
                        genres.add (genre);
                    }
                }
            }

            if (genres.size > 0) {
                return genres;
            }

            foreach (Album album in albums) {
                Gee.List<Song> songs =
                    yield library_service.get_tracks (null, artist.id, album.id);

                foreach (Song song in songs) {
                    foreach (Genre genre in song.genres) {
                        if (genre_ids.add (genre.id)) {
                            genres.add (genre);
                        }
                    }
                }
            }

            return genres;
        }

        private async Gee.List<Artist> get_top_artists (int limit) throws Error {
            Gee.List<Artist> artists = yield library_service.get_artists ();
            var artists_by_id = new HashMap<string, Artist> ();
            foreach (Artist artist in artists) {
                if (!artists_by_id.has_key (artist.id)) {
                    artists_by_id.set (artist.id, artist);
                }
            }

            Gee.List<Artist> result = new ArrayList<Artist> ();
            var selected_ids = new HashSet<string> ();
            Gee.List<Song> most_played = yield user_state_service.get_most_played (1000);

            foreach (Song song in most_played) {
                if (result.size >= limit) {
                    break;
                }

                Artist? artist = artists_by_id.get (song.artist.id);
                if (artist != null && selected_ids.add (artist.id)) {
                    result.add (artist);
                }
            }

            foreach (Artist artist in artists) {
                if (result.size >= limit) {
                    break;
                }

                if (selected_ids.add (artist.id)) {
                    result.add (artist);
                }
            }

            return result;
        }

        private Artist? find_artist (Gee.List<Artist> artists, string artist_id) {
            foreach (Artist artist in artists) {
                if (artist.id == artist_id) {
                    return artist;
                }
            }

            return null;
        }

        private int shared_genres (
            Gee.List<Genre> first,
            Gee.List<Genre> second
        ) {
            int score = 0;

            foreach (Genre first_genre in first) {
                foreach (Genre second_genre in second) {
                    if (first_genre.id == second_genre.id) {
                        score++;
                        break;
                    }
                }
            }

            return score;
        }

        private void shuffle (Gee.List<Song> songs) {
            for (int i = songs.size - 1; i > 0; i--) {
                int j = GLib.Random.int_range (0, i + 1);

                var tmp = songs[i];
                songs[i] = songs[j];
                songs[j] = tmp;
            }
        }
    }
}
