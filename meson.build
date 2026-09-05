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

project(
  'vesper',
  ['vala', 'c'],
  version: '0.1.0',
  license: 'GPL-3.0-or-later',
  meson_version: '>= 1.11.0',
  default_options: [
    'buildtype=debug',
    'warning_level=1'
  ]
)

gnome = import('gnome')

# Dependencies
cc = meson.get_compiler('c')

m_dep = cc.find_library('m', required: true)

gee_dep = dependency('gee-0.8')
glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
libpeas_dep = dependency('libpeas-2')

gtk_dep = dependency('gtk4')
libadwaita_dep = dependency('libadwaita-1')

gst_dep = dependency('gstreamer-1.0')
gst_base_dep = dependency('gstreamer-base-1.0')
gst_audio_dep = dependency('gstreamer-audio-1.0')
gst_video_dep = dependency('gstreamer-video-1.0')
gst_pbutils_dep = dependency('gstreamer-pbutils-1.0')
libsoup_dep = dependency('libsoup-3.0')

gdkpixbuf_dep = dependency('gdk-pixbuf-2.0')
xml_dep = dependency('libxml-2.0')

sqlite_dep = dependency('sqlite3')

subdir('src/core')
subdir('src/data')
subdir('src/service')
subdir('src/app')
subdir('src/plugins')