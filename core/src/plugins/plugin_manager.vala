                //
/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

using GLib;
using Peas;
using Gee;

using PiPod.Core;

namespace PiPod.Core.Plugins {
    public class PluginManager : Object {
        private Peas.Engine engine;
        private IConfig config;

        public PluginManager (string plugin_dir, IConfig config) {
            this.config = config;

            this.engine = new Peas.Engine ();

            engine.add_search_path (plugin_dir, plugin_dir);

            engine.rescan_plugins ();
        }

        /**
         * Return all loaded plugin extensions implementing the
         * requested interface.
         *
         * For example:
         *
         * get_extensions (typeof (MusicLibrary))
         * get_extensions (typeof (PlaylistProvider))
         */
        public Gee.List<GLib.Object> get_extensions (GLib.Type extension_type) {
            var extensions = new Gee.ArrayList<GLib.Object> ();
        
            uint count = engine.get_n_items ();
        
            message ("Found %u plugins", count);
        
            for (uint i = 0; i < count; i++) {
                var info = engine.get_item (i) as Peas.PluginInfo;
        
                if (info == null) {
                    warning ("Plugin %u is not a PluginInfo", i);

                    continue;
                }
        
                string module_name = info.get_module_name ();
        
                message ("Plugin: %s", module_name);
        
                try {
                    message ("  available: %s", info.is_available ().to_string ());
                } catch (GLib.Error e) {
                    warning ("  availability check failed: %s", e.message);

                    continue;
                }
        
                /*
                 * Load it.
                 */
                if (!info.is_loaded ()) {
                    message ("  loading...");
        
                    engine.set_loaded_plugins ({ module_name });
                }
        
                message ("  loaded: %s", info.is_loaded ().to_string ());
        
                /*
                 * Check the extension AFTER loading.
                 */
                bool provides = engine.provides_extension (info, extension_type);
        
                message ("  provides %s: %s", extension_type.name (), provides.to_string ());
        
                if (!provides) {
                    continue;
                }
        
                /*
                 * Create the extension.
                 */
                var extension = engine.create_extension_with_properties (
                    info,
                    extension_type,
                    {},
                    {}
                );
        
                if (extension == null) {
                    warning ("  failed to create extension");

                    continue;
                }
        
                message ("  created: %s", extension.get_type ().name ());
        
                var configurable = extension as ConfigurablePlugin;
        
                if (configurable != null) {
                    configurable.configure (config);
                }
        
                extensions.add (extension);
            }
        
            message ("Returning %d extensions", extensions.size);
        
            return extensions;
        }
    }
}