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

lrclib_plugin_sources = [
  'src/entrypoint.vala',
]

lrclib_vesper_plugin = library(
  'vesper-lrclib-plugin',
  lrclib_plugin_sources,
  dependencies: [
    gee_dep,
    glib_dep,
    gobject_dep,
    libpeas_dep,
    vesper_core_dep,
    libsoup_dep,
    json_dep,
  ],
  vala_header: 'vesper-lrclib-plugin.h',
  vala_vapi: 'vesper-lrclib-plugin.vapi',
  install_vala_header: true,
  install_vala_vapi: true,
  install: true,
)

configure_file(
  input: 'lrclib.plugin',
  output: 'lrclib.plugin',
  copy: true
)