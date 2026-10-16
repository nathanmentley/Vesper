# Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
#
# Vesper is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Vesper is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Vesper.  If not, see <https://gnu.org>.

gstreamer_plugin_sources = [
  'src/gstreamer.vala',
]

gstreamer_vesper_plugin = library(
  'vesper-gstreamer-plugin',
  gstreamer_plugin_sources,
  dependencies: [
    glib_dep,
    gobject_dep,
    libpeas_dep,
    vesper_core_dep,
    gst_dep,
    gst_base_dep,
    gst_audio_dep,
    gst_video_dep,
    m_dep,
  ],
  vala_header: 'vesper-gstreamer-plugin.h',
  vala_vapi: 'vesper-gstreamer-plugin.vapi',
  install: true,
  install_dir: get_option('libdir') / 'plugins' / 'gstreamer',
)

install_data(
  'gstreamer.plugin',
  install_dir: get_option('libdir') / 'plugins' / 'gstreamer',
)