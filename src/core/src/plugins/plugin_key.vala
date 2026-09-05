/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

namespace Vesper.Core.Plugins {
    public sealed class PluginKey : Object {
        public string id { get; construct; }

        public string source { get; construct; }

        public PluginKey (string id, string source) {
            Object (id: id, source: source);
        }

        public static uint hash (PluginKey key) {
            if (key == null) {
                return 0;
            }

            return str_hash (key.id) ^ str_hash (key.source);
        }

        public static bool equal (PluginKey a, PluginKey b) {
            if (a == b) {
                return true;
            }

            if (a == null || b == null) {
                return false;
            }

            return a.id == b.id && a.source == b.source;
        }
    }
}