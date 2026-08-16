/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

using PiPod.Core.Plugins;

namespace PiPod.Plugins.Filesystem {
    public class FilesystemMusicLibrary : Object {
        public string id { get; construct; }
        public string name { get; construct; }

        public FilesystemMusicLibrary (string id, string name) {
            Object (id: id, name: name);
        }
    }
}
