using Gee;
using Vesper.Core.Models;
using Vesper.Data;
using Vesper.Service.Libraries;

namespace Vesper.Service.UserState {
    public sealed class UserStateServiceImpl : UserStateService, Object {
        private UserStateRepository repository;
        private LibraryService library_service;

        public UserStateServiceImpl (
            UserStateRepository repository,
            LibraryService library_service
        ) {
            this.repository = repository;
            this.library_service = library_service;
        }

        public void record_play (
            string song_id,
            int64 played_at,
            int duration,
            bool completed
        ) throws Error {
            repository.record_play (song_id, played_at, duration, completed);
        }

        public SongStats? get_song_stats (string song_id) throws Error {
            return repository.get (song_id);
        }

        public Gee.List<PlayHistoryEntry> get_recently_played (
            int limit = 50
        ) throws Error {
            return repository.get_recent (limit);
        }

        public void cleanup_play_history (
            int64 retention_seconds = 90 * 24 * 60 * 60,
            int maximum_events = 1000
        ) throws Error {
            repository.cleanup (retention_seconds, maximum_events);
        }

        public bool is_favorite (string song_id) throws Error {
            return repository.is_favorite (song_id);
        }

        public void favorite (string song_id) throws Error {
            repository.add_favorite (song_id);
        }

        public void unfavorite (string song_id) throws Error {
            repository.remove_favorite (song_id);
        }

        public async Gee.List<Song> get_favorites () throws Error {
            var songs = new Gee.ArrayList<Song> ();

            foreach (string song_id in repository.get_favorite_song_ids ()) {
                Song? song = yield library_service.get_track (song_id);
                if (song != null) {
                    songs.add (song);
                }
            }

            return songs;
        }
    }
}
