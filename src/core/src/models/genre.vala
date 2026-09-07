using GLib;

namespace Vesper.Core.Models {
    public class Genre : Object {
        public string id { get; construct; }
        public string name { get; construct; }

        public Genre (string name) {
            Object (
                id: "genre:" + name,
                name: name
            );
        }

        public Genre.with_id (string id, string name) {
            Object (id: id, name: name);
        }
    }
}