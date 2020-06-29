//
//  Copyright (C) 2013 Tom Beckmann, Rico Tzschichholz
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

namespace Gala.Plugins.Zoom {
    public class Main : Gala.Plugin {
        const uint MOUSE_POLL_TIME = 50;

        Gala.WindowManager? wm = null;

        uint mouse_poll_timer = 0;
        float current_zoom = 1.0f;
        ulong wins_handler_id = 0UL;

        public override void initialize (Gala.WindowManager wm) {
            this.wm = wm;
#if HAS_MUTTER330
            var display = wm.get_display ();
#else
            var display = wm.get_screen ().get_display ();
#endif
            var schema = new GLib.Settings (Config.SCHEMA + ".keybindings");

            display.add_keybinding ("zoom-in", schema, 0, (Meta.KeyHandlerFunc) zoom_in);
            display.add_keybinding ("zoom-out", schema, 0, (Meta.KeyHandlerFunc) zoom_out);
        }

        public override void destroy () {
            if (wm == null)
                return;

#if HAS_MUTTER330
            var display = wm.get_display ();
#else
            var display = wm.get_screen ().get_display ();
#endif

            display.remove_keybinding ("zoom-in");
            display.remove_keybinding ("zoom-out");

            if (mouse_poll_timer > 0)
                Source.remove (mouse_poll_timer);
            mouse_poll_timer = 0;
        }

        [CCode (instance_pos = -1)]
#if HAS_MUTTER330
        void zoom_in (Meta.Display display, Meta.Window? window,
            Clutter.KeyEvent event, Meta.KeyBinding binding) {
#else
        void zoom_in (Meta.Display display, Meta.Screen screen,
            Meta.Window? window, Clutter.KeyEvent event, Meta.KeyBinding binding) {
#endif
            zoom (true);
        }

        [CCode (instance_pos = -1)]
#if HAS_MUTTER330
        void zoom_out (Meta.Display display, Meta.Window? window,
            Clutter.KeyEvent event, Meta.KeyBinding binding) {
#else
        void zoom_out (Meta.Display display, Meta.Screen screen,
            Meta.Window? window, Clutter.KeyEvent event, Meta.KeyBinding binding) {
#endif
            zoom (false);
        }

        void zoom (bool @in) {
            // Nothing to do if zooming out of our bounds is requested
            if (current_zoom <= 1.0f && !@in)
                return;
            else if (current_zoom >= 2.5f && @in)
                return;

            var wins = wm.ui_group;

            // Add timer to poll current mouse position to reposition window-group
            // to show requested zoomed area
            if (mouse_poll_timer == 0) {
                float mx, my;
                var client_pointer = Gdk.Display.get_default ().get_device_manager ().get_client_pointer ();
                client_pointer.get_position (null, out mx, out my);
                wins.set_pivot_point (mx / wins.width, my / wins.height);

                mouse_poll_timer = Timeout.add (MOUSE_POLL_TIME, () => {
                    client_pointer.get_position (null, out mx, out my);
#if HAS_MUTTER336
                    var new_pivot = new Graphene.Point ();
#else
                    var new_pivot = Clutter.Point.alloc ();
#endif

                    new_pivot.init (mx / wins.width, my / wins.height);
#if HAS_MUTTER336
                    if (wins.pivot_point.equal (new_pivot)) {
#else
                    if (wins.pivot_point.equals (new_pivot)) {
#endif

                        return true;
}
                    wins.save_easing_state ();
                    wins.set_easing_mode (Clutter.AnimationMode.LINEAR);
                    wins.set_easing_duration (MOUSE_POLL_TIME);
                    wins.pivot_point = new_pivot;
                    wins.restore_easing_state ();
                    return true;
                });
            }

            current_zoom += (@in ? 0.5f : -0.5f);

            if (current_zoom <= 1.0f) {
                current_zoom = 1.0f;

                if (mouse_poll_timer > 0)
                    Source.remove (mouse_poll_timer);
                mouse_poll_timer = 0;

                wins.save_easing_state ();
                wins.set_easing_mode (Clutter.AnimationMode.EASE_OUT_CUBIC);
                wins.set_easing_duration (300);
                wins.set_scale (1.0f, 1.0f);
                wins.restore_easing_state ();

                wins_handler_id = wins.transitions_completed.connect (() => {
                    wins.disconnect (wins_handler_id);
                    wins.set_pivot_point (0.0f, 0.0f);
                });

                return;
            }

            wins.save_easing_state ();
            wins.set_easing_mode (Clutter.AnimationMode.EASE_OUT_CUBIC);
            wins.set_easing_duration (300);
            wins.set_scale (current_zoom, current_zoom);
            wins.restore_easing_state ();
        }
    }
}

public Gala.PluginInfo register_plugin () {
    return Gala.PluginInfo () {
        name = "Zoom",
        author = "Gala Developers",
        plugin_type = typeof (Gala.Plugins.Zoom.Main),
        provides = Gala.PluginFunction.ADDITION,
        load_priority = Gala.LoadPriority.IMMEDIATE
    };
}
