//
//  Copyright (C) 2017 Santiago León O., Adam Bieńkowski
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
    public class SelectionArea : Clutter.Actor {
        public signal void closed ();

        public WindowManager wm { get; construct; }

        public bool cancelled { get; private set; }

        private ModalProxy? modal_proxy;
        private Gdk.Point start_point;
        private Gdk.Point end_point;
        private bool dragging = false;
        private bool clicked = false;

        public SelectionArea (WindowManager wm) {
            Object (wm: wm);
        }

        construct {
            start_point = { 0, 0 };
            end_point = { 0, 0 };
            visible = true;
            reactive = true;

            int screen_width, screen_height;
#if HAS_MUTTER330
            wm.get_display ().get_size (out screen_width, out screen_height);
#else
            wm.get_screen ().get_size (out screen_width, out screen_height);
#endif
            width = screen_width;
            height = screen_height;

            var canvas = new Clutter.Canvas ();
            canvas.set_size (screen_width, screen_height);
            canvas.draw.connect (draw_area);
            set_content (canvas);

            canvas.invalidate ();
        }

        public override bool key_press_event (Clutter.KeyEvent e) {
            if (e.keyval == Clutter.Key.Escape) {
                close ();
                cancelled = true;
                closed ();
                return true;
            }

            return false;
        }

        public override bool button_press_event (Clutter.ButtonEvent e) {
            if (dragging || e.button != 1) {
                return true;
            }

            clicked = true;

            start_point.x = (int) e.x;
            start_point.y = (int) e.y;

            return true;
        }

        public override bool button_release_event (Clutter.ButtonEvent e) {
            if (e.button != 1) {
                return true;
            }

            if (!dragging) {
                close ();
                cancelled = true;
                closed ();
                return true;
            }

            dragging = false;
            clicked = false;

            close ();
            this.hide ();
            content.invalidate ();

            closed ();
            return true;
        }

        public override bool motion_event (Clutter.MotionEvent e) {
            if (!clicked) {
                return true;
            }

            end_point.x = (int) e.x;
            end_point.y = (int) e.y;
            content.invalidate ();

            if (!dragging) {
                dragging = true;
            }

            return true;
        }

        public void close () {
#if HAS_MUTTER330
            wm.get_display ().set_cursor (Meta.Cursor.DEFAULT);
#else
            wm.get_screen ().set_cursor (Meta.Cursor.DEFAULT);
#endif

            if (modal_proxy != null) {
                wm.pop_modal (modal_proxy);
            }
        }

        public void start_selection () {
#if HAS_MUTTER330
            wm.get_display ().set_cursor (Meta.Cursor.CROSSHAIR);
#else
            wm.get_screen ().set_cursor (Meta.Cursor.CROSSHAIR);
#endif
            grab_key_focus ();

            modal_proxy = wm.push_modal ();
        }

        public void get_selection_rectangle (out int x, out int y, out int width, out int height) {
            x = int.min (start_point.x, end_point.x);
            y = int.min (start_point.y, end_point.y);
            width = (start_point.x - end_point.x).abs ();
            height = (start_point.y - end_point.y).abs ();
        }

        private bool draw_area (Cairo.Context ctx) {
            Clutter.cairo_clear (ctx);

            if (!dragging) {
                return true;
            }

            ctx.translate (0.5, 0.5);

            int x, y, w, h;
            get_selection_rectangle (out x, out y, out w, out h);

            ctx.rectangle (x, y, w, h);
            ctx.set_source_rgba (0.1, 0.1, 0.1, 0.2);
            ctx.fill ();

            ctx.rectangle (x, y, w, h);
            ctx.set_source_rgb (0.7, 0.7, 0.7);
            ctx.set_line_width (1.0);
            ctx.stroke ();

            return true;
        }
    }
}
