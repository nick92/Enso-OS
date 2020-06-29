//
//  Copyright (C) 2012 Tom Beckmann, Rico Tzschichholz
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

using Meta;

namespace Gala {
    public enum InputArea {
        NONE,
        FULLSCREEN,
        DEFAULT
    }

    public class InternalUtils {
        public static bool workspaces_only_on_primary () {
            return Prefs.get_dynamic_workspaces ()
                && Prefs.get_workspaces_only_on_primary ();
        }

        /*
         * Reload shadow settings
         */
        public static void reload_shadow () {
            var factory = ShadowFactory.get_default ();
            var settings = ShadowSettings.get_default ();
            Meta.ShadowParams shadow;

            //normal focused
            shadow = settings.get_shadowparams ("normal_focused");
            factory.set_params ("normal", true, shadow);

            //normal unfocused
            shadow = settings.get_shadowparams ("normal_unfocused");
            factory.set_params ("normal", false, shadow);

            //menus
            shadow = settings.get_shadowparams ("menu");
            factory.set_params ("menu", false, shadow);
            factory.set_params ("dropdown-menu", false, shadow);
            factory.set_params ("popup-menu", false, shadow);

            //dialog focused
            shadow = settings.get_shadowparams ("dialog_focused");
            factory.set_params ("dialog", true, shadow);
            factory.set_params ("modal_dialog", false, shadow);

            //dialog unfocused
            shadow = settings.get_shadowparams ("dialog_unfocused");
            factory.set_params ("dialog", false, shadow);
            factory.set_params ("modal_dialog", false, shadow);
        }

        /**
         * set the area where clutter can receive events
         **/
#if HAS_MUTTER330
        public static void set_input_area (Display display, InputArea area) {
            X.Xrectangle[] rects = {};
            int width, height;
            display.get_size (out width, out height);
            var geometry = display.get_monitor_geometry (display.get_primary_monitor ());

            switch (area) {
                case InputArea.FULLSCREEN:
                    X.Xrectangle rect = {0, 0, (ushort)width, (ushort)height};
                    rects = {rect};
                    break;
                case InputArea.DEFAULT:
                    var settings = new GLib.Settings (Config.SCHEMA + ".behavior");

                    // if ActionType is NONE make it 0 sized
                    ushort tl_size = (settings.get_enum ("hotcorner-topleft") != ActionType.NONE ? 1 : 0);
                    ushort tr_size = (settings.get_enum ("hotcorner-topright") != ActionType.NONE ? 1 : 0);
                    ushort bl_size = (settings.get_enum ("hotcorner-bottomleft") != ActionType.NONE ? 1 : 0);
                    ushort br_size = (settings.get_enum ("hotcorner-bottomright") != ActionType.NONE ? 1 : 0);

                    X.Xrectangle topleft = {(short)geometry.x, (short)geometry.y, tl_size, tl_size};
                    X.Xrectangle topright = {(short)(geometry.x + geometry.width - 1), (short)geometry.y, tr_size, tr_size};
                    X.Xrectangle bottomleft = {(short)geometry.x, (short)(geometry.y + geometry.height - 1), bl_size, bl_size};
                    X.Xrectangle bottomright = {(short)(geometry.x + geometry.width - 1), (short)(geometry.y + geometry.height - 1), br_size, br_size};

                    rects = {topleft, topright, bottomleft, bottomright};

                    // add plugin's requested areas
                    if (area == InputArea.FULLSCREEN || area == InputArea.DEFAULT) {
                        foreach (var rect in PluginManager.get_default ().regions) {
                            rects += rect;
                        }
                    }
                    break;
                case InputArea.NONE:
                default:
#if HAS_MUTTER334
                    unowned Meta.X11Display x11display = display.get_x11_display ();
                    x11display.clear_stage_input_region ();
#else
                    display.empty_stage_input_region ();
#endif
                    return;
            }

#if HAS_MUTTER334
            unowned Meta.X11Display x11display = display.get_x11_display ();
            var xregion = X.Fixes.create_region (x11display.get_xdisplay (), rects);
            x11display.set_stage_input_region (xregion);
#else
            var xregion = X.Fixes.create_region (display.get_x11_display ().get_xdisplay (), rects);
            Util.set_stage_input_region (display, xregion);
#endif
        }
#else
        public static void set_input_area (Screen screen, InputArea area) {
            var display = screen.get_display ();

            X.Xrectangle[] rects = {};
            int width, height;
            screen.get_size (out width, out height);
            var geometry = screen.get_monitor_geometry (screen.get_primary_monitor ());

            switch (area) {
                case InputArea.FULLSCREEN:
                    X.Xrectangle rect = {0, 0, (ushort)width, (ushort)height};
                    rects = {rect};
                    break;
                case InputArea.DEFAULT:
                    var settings = new GLib.Settings (Config.SCHEMA + ".behavior");

                    // if ActionType is NONE make it 0 sized
                    ushort tl_size = (settings.get_enum ("hotcorner-topleft") != ActionType.NONE ? 1 : 0);
                    ushort tr_size = (settings.get_enum ("hotcorner-topright") != ActionType.NONE ? 1 : 0);
                    ushort bl_size = (settings.get_enum ("hotcorner-bottomleft") != ActionType.NONE ? 1 : 0);
                    ushort br_size = (settings.get_enum ("hotcorner-bottomright") != ActionType.NONE ? 1 : 0);

                    X.Xrectangle topleft = {(short)geometry.x, (short)geometry.y, tl_size, tl_size};
                    X.Xrectangle topright = {(short)(geometry.x + geometry.width - 1), (short)geometry.y, tr_size, tr_size};
                    X.Xrectangle bottomleft = {(short)geometry.x, (short)(geometry.y + geometry.height - 1), bl_size, bl_size};
                    X.Xrectangle bottomright = {(short)(geometry.x + geometry.width - 1), (short)(geometry.y + geometry.height - 1), br_size, br_size};

                    rects = {topleft, topright, bottomleft, bottomright};

                    // add plugin's requested areas
                    if (area == InputArea.FULLSCREEN || area == InputArea.DEFAULT) {
                        foreach (var rect in PluginManager.get_default ().regions) {
                            rects += rect;
                        }
                    }
                    break;
                case InputArea.NONE:
                default:
                    screen.empty_stage_input_region ();
                    return;
            }

            var xregion = X.Fixes.create_region (display.get_xdisplay (), rects);
            screen.set_stage_input_region (xregion);
        }
#endif

        /**
         * Inserts a workspace at the given index. To ensure the workspace is not immediately
         * removed again when in dynamic workspaces, the window is first placed on it.
         *
         * @param index  The index at which to insert the workspace
         * @param new_window A window that should be moved to the new workspace
         */
        public static void insert_workspace_with_window (int index, Window new_window) {
            unowned WorkspaceManager workspace_manager = WorkspaceManager.get_default ();
            workspace_manager.freeze_remove ();

            new_window.change_workspace_by_index (index, false);

#if HAS_MUTTER330
            unowned List<WindowActor> actors = new_window.get_display ().get_window_actors ();
#else
            unowned List<WindowActor> actors = new_window.get_screen ().get_window_actors ();
#endif
            foreach (unowned Meta.WindowActor actor in actors) {
                if (actor.is_destroyed ())
                    continue;

                unowned Meta.Window window = actor.get_meta_window ();
                if (window == new_window)
                    continue;

                var current_index = window.get_workspace ().index ();
                if (current_index >= index
                    && !window.on_all_workspaces) {
                    window.change_workspace_by_index (current_index + 1, true);
                }
            }

            workspace_manager.thaw_remove ();
            workspace_manager.cleanup ();
        }

        // Code ported from KWin present windows effect
        // https://projects.kde.org/projects/kde/kde-workspace/repository/revisions/master/entry/kwin/effects/presentwindows/presentwindows.cpp

        // constants, mainly for natural expo
        const int GAPS = 10;
        const int MAX_TRANSLATIONS = 100000;
        const int ACCURACY = 20;

        // some math utilities
        static int squared_distance (Gdk.Point a, Gdk.Point b) {
            var k1 = b.x - a.x;
            var k2 = b.y - a.y;

            return k1 * k1 + k2 * k2;
        }

        static Meta.Rectangle rect_adjusted (Meta.Rectangle rect, int dx1, int dy1, int dx2, int dy2) {
            return {rect.x + dx1, rect.y + dy1, rect.width + (-dx1 + dx2), rect.height + (-dy1 + dy2)};
        }

        static Gdk.Point rect_center (Meta.Rectangle rect) {
            return {rect.x + rect.width / 2, rect.y + rect.height / 2};
        }

        public struct TilableWindow {
            Meta.Rectangle rect;
            void *id;
        }

        public static List<TilableWindow?> calculate_grid_placement (Meta.Rectangle area, List<TilableWindow?> windows) {
            uint window_count = windows.length ();
            int columns = (int)Math.ceil (Math.sqrt (window_count));
            int rows = (int)Math.ceil (window_count / (double)columns);

            // Assign slots
            int slot_width = area.width / columns;
            int slot_height = area.height / rows;

            TilableWindow?[] taken_slots = {};
            taken_slots.resize (rows * columns);

            // precalculate all slot centers
            Gdk.Point[] slot_centers = {};
            slot_centers.resize (rows * columns);
            for (int x = 0; x < columns; x++) {
                for (int y = 0; y < rows; y++) {
                    slot_centers[x + y * columns] = {
                        area.x + slot_width * x + slot_width / 2,
                        area.y + slot_height * y + slot_height / 2
                    };
                }
            }

            // Assign each window to the closest available slot
            var tmplist = windows.copy ();
            while (tmplist.length () > 0) {
                unowned List<unowned TilableWindow?> link = tmplist.nth (0);
                var window = link.data;
                var rect = window.rect;

                var slot_candidate = -1;
                var slot_candidate_distance = int.MAX;
                var pos = rect_center (rect);

                // all slots
                for (int i = 0; i < columns * rows; i++) {
                    if (i > window_count - 1)
                        break;

                    var dist = squared_distance (pos, slot_centers[i]);

                    if (dist < slot_candidate_distance) {
                        // window is interested in this slot
                        var occupier = taken_slots[i];
                        if (occupier == window)
                            continue;

                        if (occupier == null || dist < squared_distance (rect_center (occupier.rect), slot_centers[i])) {
                            // either nobody lives here, or we're better - takeover the slot if it's our best
                            slot_candidate = i;
                            slot_candidate_distance = dist;
                        }
                    }
                }

                if (slot_candidate == -1)
                    continue;

                if (taken_slots[slot_candidate] != null)
                    tmplist.prepend (taken_slots[slot_candidate]);

                tmplist.remove_link (link);
                taken_slots[slot_candidate] = window;
            }

            var result = new List<TilableWindow?> ();

            // see how many windows we have on the last row
            int left_over = (int)window_count - columns * (rows - 1);

            for (int slot = 0; slot < columns * rows; slot++) {
                var window = taken_slots[slot];
                // some slots might be empty
                if (window == null)
                    continue;

                var rect = window.rect;

                // Work out where the slot is
                Meta.Rectangle target = {area.x + (slot % columns) * slot_width,
                                         area.y + (slot / columns) * slot_height,
                                         slot_width,
                                         slot_height};
                target = rect_adjusted (target, 10, 10, -10, -10);

                float scale;
                if (target.width / (double)rect.width < target.height / (double)rect.height) {
                    // Center vertically
                    scale = target.width / (float)rect.width;
                    target.y += (target.height - (int)(rect.height * scale)) / 2;
                    target.height = (int)Math.floorf (rect.height * scale);
                } else {
                    // Center horizontally
                    scale = target.height / (float)rect.height;
                    target.x += (target.width - (int)(rect.width * scale)) / 2;
                    target.width = (int)Math.floorf (rect.width * scale);
                }

                // Don't scale the windows too much
                if (scale > 1.0) {
                    scale = 1.0f;
                    target = {rect_center (target).x - (int)Math.floorf (rect.width * scale) / 2,
                              rect_center (target).y - (int)Math.floorf (rect.height * scale) / 2,
                              (int)Math.floorf (scale * rect.width),
                              (int)Math.floorf (scale * rect.height)};
                }

                // put the last row in the center, if necessary
                if (left_over != columns && slot >= columns * (rows - 1))
                    target.x += (columns - left_over) * slot_width / 2;

                result.prepend ({ target, window.id });
            }

            result.reverse ();
            return result;
        }

        public static inline bool get_window_is_normal (Meta.Window window) {
            switch (window.get_window_type ()) {
                case Meta.WindowType.NORMAL:
                case Meta.WindowType.DIALOG:
                case Meta.WindowType.MODAL_DIALOG:
                    return true;
                default:
                    return false;
            }
        }

        public static int get_ui_scaling_factor () {
            return Meta.Backend.get_backend ().get_settings ().get_ui_scaling_factor ();
        }
    }
}
