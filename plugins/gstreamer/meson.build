# Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
#
# PiPod is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# PiPod is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with PiPod.  If not, see <https://gnu.org>.

gstreamer_plugin_sources = [
  'src/gstreamer.vala',
]

gstreamer_pipod_plugin = library(
  'pipod-gstreamer-plugin',
  gstreamer_plugin_sources,
  dependencies: [
    glib_dep,
    gobject_dep,
    libpeas_dep,
    pipod_plugin_dep,
    gst_dep,
  ],
  vala_header: 'pipod-gstreamer-plugin.h',
  vala_vapi: 'pipod-gstreamer-plugin.vapi',
  install_vala_header: true,
  install_vala_vapi: true,
  install: true,
)

configure_file(
  input: 'gstreamer.plugin',
  output: 'gstreamer.plugin',
  copy: true
)