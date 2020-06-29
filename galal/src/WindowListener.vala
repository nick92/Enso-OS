//
//  Copyright (C) 2014 Tom Beckmann
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

using Gala;
using Meta;

namespace Gala {
    public struct WindowGeometry {
        Meta.Rectangle inner;
        Meta.Rectangle outer;
    }

    public class WindowListener : Object {
        static WindowListener? instance = null;

#if HAS_MUTTER330
        public static void init (Meta.Display display) {
            if (instance != null)
                return;

            instance = new WindowListener ();

            foreach (unowned Meta.WindowActor actor in display.get_window_actors ()) {
                if (actor.is_destroyed ())
                    continue;

                unowned Meta.Window window = actor.get_meta_window ();
                if (window.window_type == WindowType.NORMAL)
                    instance.monitor_window (window);
            }

            display.window_created.connect ((window) => {
                if (window.window_type == WindowType.NORMAL)
                    instance.monitor_window (window);
            });
        }
#else
        public static void init (Screen screen) {
            if (instance != null)
                return;

            instance = new WindowListener ();

            foreach (unowned Meta.WindowActor actor in screen.get_window_actors ()) {
                if (actor.is_destroyed ())
                    continue;

                unowned Meta.Window window = actor.get_meta_window ();
                if (window.window_type == WindowType.NORMAL)
                    instance.monitor_window (window);
            }

            screen.get_display ().window_created.connect ((window) => {
                if (window.window_type == WindowType.NORMAL)
                    instance.monitor_window (window);
            });
        }
#endif

        public static unowned WindowListener get_default () requires (instance != null) {
            return instance;
        }

        public signal void window_no_longer_on_all_workspaces (Window window);

        Gee.HashMap<Meta.Window, WindowGeometry?> unmaximized_state_geometry;

        WindowListener () {
            unmaximized_state_geometry = new Gee.HashMap<Meta.Window, WindowGeometry?> ();
        }

        void monitor_window (Window window) {
            window.notify.connect (window_notify);
            window.unmanaged.connect (window_removed);

            window_maximized_changed (window);
        }

        void window_notify (Object object, ParamSpec pspec) {
            var window = (Window) object;

            switch (pspec.name) {
                case "maximized-horizontally":
                case "maximized-vertically":
                    window_maximized_changed (window);
                    break;
                case "on-all-workspaces":
                    window_on_all_workspaces_changed (window);
                    break;
            }
        }

        void window_on_all_workspaces_changed (Window window) {
            if (window.on_all_workspaces)
                return;

            window_no_longer_on_all_workspaces (window);
        }

        void window_maximized_changed (Window window) {
            WindowGeometry window_geometry = {};
            window_geometry.inner = window.get_frame_rect ();
            window_geometry.outer = window.get_buffer_rect ();

            unmaximized_state_geometry.@set (window, window_geometry);
        }

        public WindowGeometry? get_unmaximized_state_geometry (Window window) {
            return unmaximized_state_geometry.@get (window);
        }

        void window_removed (Window window) {
            window.notify.disconnect (window_notify);
            window.unmanaged.disconnect (window_removed);
        }
    }
}
