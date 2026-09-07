using Gee;
using Vesper.Core.Models;
using Vesper.Data;

namespace Vesper.Service.UserState {
    public sealed class UserStateServiceImpl : UserStateService, Object {
        private UserStateRepository repository;

        public UserStateServiceImpl (UserStateRepository repository) {
            this.repository = repository;
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
    }
}
