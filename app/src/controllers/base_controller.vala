/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://gnu.org>.
 */

using Gtk;
using GLib;

using PiPod.App.Views;

namespace PiPod.App.Controllers {
    public abstract class BaseController<TView> : Object {
        protected TView view;

        protected BaseController (TView view) {
            this.view = view;
            connect_view ();
        }

        public void mount (Box root) {
            if (view is BaseView) {
                root.append ((BaseView)view);
            }
        }

        public void show () {
            if (view is BaseView) {
                ((BaseView)view).visible = true;
            }
        }

        public void hide () {
            if (view is BaseView) {
                ((BaseView)view).visible = false;
            }
        }

        public void toggle_visibility () {
            if (view is BaseView) {
                ((BaseView)view).visible = ((BaseView)view).visible ? false : true;
            }
        }

        protected abstract void connect_view ();
    }
}