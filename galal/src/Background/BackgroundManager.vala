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

namespace Gala {
    public class BackgroundManager : Meta.BackgroundGroup {
        const string BACKGROUND_SCHEMA = "org.gnome.desktop.background";
        const int FADE_ANIMATION_TIME = 1000;

        public signal void changed ();

#if HAS_MUTTER330
        public Meta.Display display { get; construct; }
#else
        public Meta.Screen screen { get; construct; }
#endif
        public int monitor_index { get; construct; }
        public bool control_position { get; construct; }

        BackgroundSource background_source;
        Meta.BackgroundActor background_actor;
        Meta.BackgroundActor? new_background_actor = null;

#if HAS_MUTTER330
        public BackgroundManager (Meta.Display display, int monitor_index, bool control_position = true) {
            Object (display: display, monitor_index: monitor_index, control_position: control_position);
        }
#else
        public BackgroundManager (Meta.Screen screen, int monitor_index, bool control_position = true) {
            Object (screen: screen, monitor_index: monitor_index, control_position: control_position);
        }
#endif

        construct {
#if HAS_MUTTER330
            background_source = BackgroundCache.get_default ().get_background_source (display, BACKGROUND_SCHEMA);
#else
            background_source = BackgroundCache.get_default ().get_background_source (screen, BACKGROUND_SCHEMA);
#endif

            background_actor = create_background_actor ();

            destroy.connect (on_destroy);
        }

        void on_destroy () {
            BackgroundCache.get_default ().release_background_source (BACKGROUND_SCHEMA);
            background_source = null;

            if (new_background_actor != null) {
                new_background_actor.destroy ();
                new_background_actor = null;
            }

            if (background_actor != null) {
                background_actor.destroy ();
                background_actor = null;
            }
        }

        void swap_background_actor () {
            return_if_fail (new_background_actor != null);

            var old_background_actor = background_actor;
            background_actor = new_background_actor;
            new_background_actor = null;

            if (old_background_actor == null)
                return;

            var transition = new Clutter.PropertyTransition ("opacity");
            transition.set_from_value (255);
            transition.set_to_value (0);
            transition.duration = FADE_ANIMATION_TIME;
            transition.progress_mode = Clutter.AnimationMode.EASE_OUT_QUAD;
            transition.remove_on_complete = true;
            transition.completed.connect (() => {
                old_background_actor.destroy ();

                changed ();
            });

            old_background_actor.add_transition ("fade-out", transition);
        }

        void update_background_actor () {
            if (new_background_actor != null) {
                // Skip displaying existing background queued for load
                new_background_actor.destroy ();
                new_background_actor = null;
            }

            new_background_actor = create_background_actor ();
            new_background_actor.vignette_sharpness = background_actor.vignette_sharpness;
            new_background_actor.brightness = background_actor.brightness;
            new_background_actor.visible = background_actor.visible;

            var background = new_background_actor.background.get_data<unowned Background> ("delegate");

            if (background.is_loaded) {
                swap_background_actor ();
                return;
            }

            ulong handler = 0;
            handler = background.loaded.connect (() => {
                SignalHandler.disconnect (background, handler);
                background.set_data<ulong> ("background-loaded-handler", 0);

                swap_background_actor ();
            });
            background.set_data<ulong> ("background-loaded-handler", handler);
        }

        public void set_size (float width, float height) {
            background_actor.set_size (width, height);
        }

        Meta.BackgroundActor create_background_actor () {
            var background = background_source.get_background (monitor_index);
#if HAS_MUTTER330
            var background_actor = new Meta.BackgroundActor (display, monitor_index);
#else
            var background_actor = new Meta.BackgroundActor (screen, monitor_index);
#endif

            background_actor.background = background.background;

            insert_child_below (background_actor, null);

#if HAS_MUTTER330
            var monitor = display.get_monitor_geometry (monitor_index);
#else
            var monitor = screen.get_monitor_geometry (monitor_index);
#endif

            background_actor.set_size (monitor.width, monitor.height);

            if (control_position) {
                background_actor.set_position (monitor.x, monitor.y);
            }

            ulong changed_handler = 0;
            changed_handler = background.changed.connect (() => {
                SignalHandler.disconnect (background, changed_handler);
                changed_handler = 0;
                update_background_actor ();
            });

            background_actor.destroy.connect (() => {
                if (changed_handler != 0) {
                    SignalHandler.disconnect (background, changed_handler);
                    changed_handler = 0;
                }

                var loaded_handler = background.get_data<ulong> ("background-loaded-handler");
                if (loaded_handler != 0) {
                    SignalHandler.disconnect (background, loaded_handler);
                    background.set_data<ulong> ("background-loaded-handler", 0);
                }
            });

            return background_actor;
        }
    }
}
