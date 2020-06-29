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

using Clutter;
using Meta;

namespace Gala {
    /**
     * More or less utility class to contain a WindowCloneContainer for each
     * non-primary monitor. It's the pendant to the WorkspaceClone which is
     * only placed on the primary monitor. It also draws a wallpaper behind itself
     * as the WindowGroup is hidden while the view is active. Only used when
     * workspaces-only-on-primary is set to true.
     */
    public class MonitorClone : Actor {
        public signal void window_selected (Window window);

#if HAS_MUTTER330
        public Meta.Display display { get; construct; }
#else
        public Screen screen { get; construct; }
#endif
        public int monitor { get; construct; }

        WindowCloneContainer window_container;
        BackgroundManager background;

#if HAS_MUTTER330
        public MonitorClone (Meta.Display display, int monitor) {
            Object (display: display, monitor: monitor);
        }
#else
        public MonitorClone (Screen screen, int monitor) {
            Object (screen: screen, monitor: monitor);
        }
#endif

        construct {
            reactive = true;

#if HAS_MUTTER330
            background = new BackgroundManager (display, monitor, false);
#else
            background = new BackgroundManager (screen, monitor, false);
#endif
            background.set_easing_duration (MultitaskingView.ANIMATION_DURATION);

            window_container = new WindowCloneContainer ();
            window_container.window_selected.connect ((w) => { window_selected (w); });
#if HAS_MUTTER330
            display.restacked.connect (window_container.restack_windows);

            display.window_entered_monitor.connect (window_entered);
            display.window_left_monitor.connect (window_left);
#else
            screen.restacked.connect (window_container.restack_windows);

            screen.window_entered_monitor.connect (window_entered);
            screen.window_left_monitor.connect (window_left);
#endif

#if HAS_MUTTER330
            unowned GLib.List<Meta.WindowActor> window_actors = display.get_window_actors ();
#else
            unowned GLib.List<Meta.WindowActor> window_actors = screen.get_window_actors ();
#endif
            foreach (unowned Meta.WindowActor window_actor in window_actors) {
                if (window_actor.is_destroyed ())
                    continue;

                unowned Meta.Window window = window_actor.get_meta_window ();
                if (window.get_monitor () == monitor) {
                    window_entered (monitor, window);
                }
            }

            add_child (background);
            add_child (window_container);

            var drop = new DragDropAction (DragDropActionType.DESTINATION, "multitaskingview-window");
            add_action (drop);

            update_allocation ();
        }

        ~MonitorClone () {
#if HAS_MUTTER330
            display.window_entered_monitor.disconnect (window_entered);
            display.window_left_monitor.disconnect (window_left);
            display.restacked.disconnect (window_container.restack_windows);
#else
            screen.window_entered_monitor.disconnect (window_entered);
            screen.window_left_monitor.disconnect (window_left);
            screen.restacked.disconnect (window_container.restack_windows);
#endif
        }

        /**
         * Make sure the MonitorClone is at the location of the monitor on the stage
         */
        public void update_allocation () {
#if HAS_MUTTER330
            var monitor_geometry = display.get_monitor_geometry (monitor);
#else
            var monitor_geometry = screen.get_monitor_geometry (monitor);
#endif

            set_position (monitor_geometry.x, monitor_geometry.y);
            set_size (monitor_geometry.width, monitor_geometry.height);
            window_container.set_size (monitor_geometry.width, monitor_geometry.height);
        }

        /**
         * Animate the windows from their old location to a tiled layout
         */
        public void open () {
            window_container.open ();
            // background.opacity = 0; TODO consider this option
        }

        /**
         * Animate the windows back to their old location
         */
        public void close () {
            window_container.close ();
            background.opacity = 255;
        }

        void window_left (int window_monitor, Window window) {
            if (window_monitor != monitor)
                return;

            window_container.remove_window (window);
        }

        void window_entered (int window_monitor, Window window) {
            if (window_monitor != monitor || window.window_type != WindowType.NORMAL)
                return;

            window_container.add_window (window);
        }
    }
}
