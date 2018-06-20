/***

    Copyright (C) 2018 Enso Developers

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as
    published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses>

***/

namespace Welcome {

    const int MIN_WIDTH = 500;
    const int MIN_HEIGHT = 600;

    public class WelcomeWindow : Gtk.Window {

        private GLib.Settings welcome_settings = new GLib.Settings ("org.enso.welcome");

        /* GUI components */
        private Granite.Widgets.Welcome welcome_welcome;     // The Welcome screen when there are no tasks
        private Gtk.Image 				rose_image;
        private Gtk.Grid                grid;               // Container for everything
        private Gtk.Grid                bottom;               // Container for everything
        private Gtk.Button				button_started;
        private Gtk.Button				button_close;
        private Gtk.CssProvider 		provider;
        private Gtk.Stack 				stack;
        private Gtk.Revealer 			view_selector_revealer;

        /* Views */
        private WelcomeView				welcome_view;
        private OptionsView				options_view;

        public WelcomeWindow (bool start_launch) {
            this.get_style_context ().add_class ("rounded");

            this.set_size_request(MIN_WIDTH, MIN_HEIGHT);

            // Set up geometry
            Gdk.Geometry geo = Gdk.Geometry();
            //geo.min_width = MIN_WIDTH;
            //geo.min_height = MIN_HEIGHT;
            geo.max_width = 1024;
            geo.max_height = 2048;
            geo.win_gravity = Gdk.Gravity.CENTER;

            this.set_geometry_hints(null, geo, Gdk.WindowHints.MIN_SIZE | Gdk.WindowHints.MAX_SIZE);

            restore_window_position ();

            var first = welcome_settings.get_boolean ("first-time");

            if(start_launch && !first)
              main_quit ();

            setup_ui ();    // Set up the GUI
        }

        /**
         * Builds all of the widgets and arranges them in the window.
         */
        private void setup_ui () {
            this.set_title ("Welcome");
            grid = new Gtk.Grid ();
            //this.key_press_event.connect (key_down_event);

			      button_started = new Gtk.Button ();
            button_started.label = "Get Started";
            button_started.valign = Gtk.Align.END;
            button_started.halign = Gtk.Align.END;
            button_started.hexpand = true;
            button_started.get_style_context ().add_class ("button-green");

            button_started.clicked.connect (() => {
      				stack.set_visible_child_name ("options");
      				button_started.visible = false;
      			});

            button_close = new Gtk.Button ();
            button_close.label = "Close";
            button_close.valign = Gtk.Align.END;
            button_close.halign = Gtk.Align.START;
            button_close.hexpand = true;
            button_close.get_style_context ().add_class ("button-red");

            button_close.clicked.connect (() => {
              welcome_settings.set_boolean ("first-time", false);
      				main_quit ();
      			});

            bottom = new Gtk.Grid ();
            bottom.orientation = Gtk.Orientation.HORIZONTAL;
            bottom.margin_start = 10;
            bottom.margin_end = 10;
            bottom.margin_top = 10;
            bottom.margin_bottom = 10;

            bottom.add(button_close);
            bottom.add(button_started);

            welcome_welcome.expand = true;

            stack = new Gtk.Stack ();
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

            welcome_view = new WelcomeView ();
            options_view = new OptionsView ();

            stack.add_named (welcome_view, "welcome");
            stack.add_named (options_view, "options");

            stack.set_visible_child_name ("welcome");

            grid.expand = true;   // expand the box to fill the whole window
            grid.row_homogeneous = false;
            //grid.attach (welcome_welcome, 0, 0, 1, 1);
            grid.attach (stack, 0, 0, 1, 1);
            grid.attach (bottom, 0, 1, 1, 1);

            this.add (grid);
        }

        /**
         *  Restore window position.
         */
        public void restore_window_position () {
            var position = welcome_settings.get_value ("window-position");
            var win_size = welcome_settings.get_value ("window-size");

            /*if (position.n_children () == 2) {
                var x = (int32) position.get_child_value (0);
                var y = (int32) position.get_child_value (1);

                debug ("Moving window to coordinates %d, %d", x, y);
                this.move (x, y);
            } else {*/
                debug ("Moving window to the centre of the screen");
                this.window_position = Gtk.WindowPosition.CENTER;
            //}

            if (win_size.n_children () == 2) {
                var width =  (int32) win_size.get_child_value (0);
                                var height = (int32) win_size.get_child_value (1);

                                debug ("Resizing to width and height: %d, %d", width, height);
                this.resize (width, height);
            } else {
                debug ("Not resizing window");
            }
        }

        /**
         *  Save window position.
         */
        public void save_window_position () {
            int x, y, width, height;
            this.get_position (out x, out y);
            this.get_size (out width, out height);
            debug ("Saving window position to %d, %d", x, y);
            welcome_settings.set_value ("window-position", new int[] { x, y });
            debug ("Saving window size of width and height: %d, %d", width, height);
            welcome_settings.set_value ("window-size", new int[] { width, height });
        }

        /**
         *  Quit from the program.
         */
        public bool main_quit () {
            save_window_position ();
            this.destroy ();

            return false;
        }
    }
}
