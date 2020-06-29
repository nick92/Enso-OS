//
//  Copyright (C) 2015 Rory J Sanderson
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

namespace Gala.Plugins.MaskCorners {
    public class Main : Gala.Plugin {
        Gala.WindowManager? wm = null;
#if HAS_MUTTER330
        Display display;
#else
        Screen screen;
#endif
        Settings settings;

        List<Actor>[] cornermasks;
        private int corner_radius = 6;

        public override void initialize (Gala.WindowManager wm) {
            this.wm = wm;
#if HAS_MUTTER330
            display = wm.get_display ();
#else
            screen = wm.get_screen ();
#endif
            settings = Settings.get_default ();

            setup_cornermasks ();

            settings.changed.connect (resetup_cornermasks);
        }

        public override void destroy () {
            destroy_cornermasks ();
        }

        void setup_cornermasks () {
            if (!settings.enable)
                return;

            var scale = Utils.get_ui_scaling_factor ();

#if HAS_MUTTER330
            int n_monitors = display.get_n_monitors ();
#else
            int n_monitors = screen.get_n_monitors ();
#endif
            cornermasks = new List<Actor>[n_monitors];
            corner_radius = corner_radius * scale;

            if (settings.only_on_primary) {
#if HAS_MUTTER330
                add_cornermasks (display.get_primary_monitor ());
#else
                add_cornermasks (screen.get_primary_monitor ());
#endif
            } else {
                for (int m = 0; m < n_monitors; m++)
                    add_cornermasks (m);
            }

#if HAS_MUTTER330
            if (settings.disable_on_fullscreen)
                display.in_fullscreen_changed.connect (fullscreen_changed);

            unowned Meta.MonitorManager monitor_manager = Meta.MonitorManager.@get ();
            monitor_manager.monitors_changed.connect (resetup_cornermasks);

            display.gl_video_memory_purged.connect (resetup_cornermasks);
#else
            if (settings.disable_on_fullscreen)
                screen.in_fullscreen_changed.connect (fullscreen_changed);

            screen.monitors_changed.connect (resetup_cornermasks);

            screen.get_display ().gl_video_memory_purged.connect (resetup_cornermasks);
#endif
        }

        void destroy_cornermasks () {
#if HAS_MUTTER330
            display.gl_video_memory_purged.disconnect (resetup_cornermasks);
#else
            screen.get_display ().gl_video_memory_purged.disconnect (resetup_cornermasks);
#endif

#if HAS_MUTTER330
            unowned Meta.MonitorManager monitor_manager = Meta.MonitorManager.@get ();
            monitor_manager.monitors_changed.disconnect (resetup_cornermasks);
            display.in_fullscreen_changed.disconnect (fullscreen_changed);
#else
            screen.monitors_changed.disconnect (resetup_cornermasks);
            screen.in_fullscreen_changed.disconnect (fullscreen_changed);
#endif

            foreach (unowned List<Actor> list in cornermasks) {
                foreach (Actor actor in list)
                    actor.destroy ();
            }
        }

        void resetup_cornermasks () {
            destroy_cornermasks ();
            setup_cornermasks ();
        }

        void fullscreen_changed () {
#if HAS_MUTTER330
            for (int i = 0; i < display.get_n_monitors (); i++) {
                foreach (Actor actor in cornermasks[i]) {
                    if (display.get_monitor_in_fullscreen (i))
                        actor.hide ();
                    else
                        actor.show ();
                }
             }
#else
            for (int i = 0; i < screen.get_n_monitors (); i++) {
                foreach (Actor actor in cornermasks[i]) {
                    if (screen.get_monitor_in_fullscreen (i))
                        actor.hide ();
                    else
                        actor.show ();
                }
             }
#endif
        }

        void add_cornermasks (int monitor_no) {
#if HAS_MUTTER330
            var monitor_geometry = display.get_monitor_geometry (monitor_no);
#else
            var monitor_geometry = screen.get_monitor_geometry (monitor_no);
#endif

            Canvas canvas = new Canvas ();
            canvas.set_size (corner_radius, corner_radius);
            canvas.draw.connect (draw_cornermask);
            canvas.invalidate ();

            Actor actor = new Actor ();
            actor.set_content (canvas);
            actor.set_size (corner_radius, corner_radius);
            actor.set_position (monitor_geometry.x, monitor_geometry.y);
            actor.set_pivot_point ((float) 0.5, (float) 0.5);

            cornermasks[monitor_no].append (actor);
            wm.stage.add_child (actor);

            for (int p = 1; p < 4; p++) {
                Clone clone = new Clone (actor);
                clone.rotation_angle_z = p * 90;

                switch (p) {
                    case 1:
                        clone.set_position (monitor_geometry.x + monitor_geometry.width, monitor_geometry.y);
                        break;
                    case 2:
                        clone.set_position (monitor_geometry.x + monitor_geometry.width, monitor_geometry.y + monitor_geometry.height);
                        break;
                    case 3:
                        clone.set_position (monitor_geometry.x, monitor_geometry.y + monitor_geometry.height);
                        break;
                }

                cornermasks[monitor_no].append (clone);
                wm.stage.add_child (clone);
            }
        }

        bool draw_cornermask (Cairo.Context context) {
            var buffer = new Granite.Drawing.BufferSurface (corner_radius, corner_radius);
            var buffer_context = buffer.context;

            buffer_context.arc (corner_radius, corner_radius, corner_radius, Math.PI, 1.5 * Math.PI);
            buffer_context.line_to (0, 0);
            buffer_context.line_to (0, corner_radius);
            buffer_context.set_source_rgb (0, 0, 0);
            buffer_context.fill ();

            context.set_operator (Cairo.Operator.CLEAR);
            context.paint ();
            context.set_operator (Cairo.Operator.OVER);
            context.set_source_surface (buffer.surface, 0, 0);
            context.paint ();

            return true;
        }
    }
}

public Gala.PluginInfo register_plugin () {
    return {
        "Mask Corners",
        "Gala Developers",
        typeof (Gala.Plugins.MaskCorners.Main),
        Gala.PluginFunction.ADDITION,
        Gala.LoadPriority.IMMEDIATE
    };
}
