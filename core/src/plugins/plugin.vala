/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

using Gee;
using PiPod.Core.Models;

namespace PiPod.Core.Plugins {
    public interface Plugin : Object {
        public abstract string id { get; }

        public abstract string source { get; }
    }
}