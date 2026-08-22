/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

using PiPod.Core.Models;

namespace PiPod.Core.Settings {
    public sealed class SettingDefinition : Object {
        public string source { get; construct; }
        public string key { get; construct; }
        public string name { get; construct; }
        public string description { get; construct; }
        public SettingType setting_type { get; construct; }

        public SettingDefinition (
            string source,
            string key,
            string name,
            string description,
            SettingType setting_type
        ) {
            Object (
                source: source,
                key: key,
                name: name,
                description: description,
                setting_type: setting_type
            );
        }
    }
}
