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

filesystem_plugin_sources = [
  'src/filesystem_music_library.vala',
  'src/metadata_reader.vala',
]

filesystem_vesper_plugin = library(
  'vesper-filesystem-plugin',
  filesystem_plugin_sources,
  dependencies: [
    glib_dep,
    gobject_dep,
    libpeas_dep,
    gst_dep,
    gst_pbutils_dep,
    vesper_core_dep,
  ],
  vala_header: 'vesper-filesystem-plugin.h',
  vala_vapi: 'vesper-filesystem-plugin.vapi',
  install_vala_header: true,
  install_vala_vapi: true,
  install: true,
)

configure_file(
  input: 'filesystem.plugin',
  output: 'filesystem.plugin',
  copy: true
)