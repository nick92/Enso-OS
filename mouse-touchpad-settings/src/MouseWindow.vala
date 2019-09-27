

/***

    Copyright (C) 2019 Enso Developers

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

public class MouseTouchpad.PlugWindow : Gtk.Window {

    private Backend.MouseSettings mouse_settings;
    private Backend.TouchpadSettings touchpad_settings;

    private Gtk.Stack stack;
    private Gtk.ScrolledWindow scrolled;

    private GeneralView general_view;
    private MouseView mouse_view;
    private TouchpadView touchpad_view;
  
    public PlugWindow () {
      // Set up geometry
      Gdk.Geometry geo = new Gdk.Geometry();
      geo.min_width = 700;
      geo.min_height = 600;
      geo.max_width = 1024;
      geo.max_height = 2048;
  
      this.set_geometry_hints(null, geo, Gdk.WindowHints.MIN_SIZE | Gdk.WindowHints.MAX_SIZE);
      this.set_title("Mouse Settings");
      this.add(get_widget ());
    }


    public Gtk.Widget get_widget () {
        if (scrolled == null) {
            load_settings ();
            
            weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
            default_theme.add_resource_path ("/io/elementary/switchboard/mouse-touchpad");

            general_view = new GeneralView (mouse_settings);
            mouse_view = new MouseView ();
            touchpad_view = new TouchpadView (touchpad_settings);

            stack = new Gtk.Stack ();
            stack.margin = 12;
            stack.add_titled (general_view, "general", _("General"));
            stack.add_titled (mouse_view, "mouse", _("Mouse"));
            stack.add_titled (touchpad_view, "touchpad", _("Touchpad"));

            var switcher = new Gtk.StackSwitcher ();
            switcher.halign = Gtk.Align.CENTER;
            switcher.homogeneous = true;
            switcher.margin = 12;
            switcher.stack = stack;

            var main_grid = new Gtk.Grid ();
            main_grid.halign = Gtk.Align.CENTER;
            main_grid.attach (switcher, 0, 0, 1, 1);
            main_grid.attach (stack, 0, 1, 1, 1);

            scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.add (main_grid);
            scrolled.show_all ();
        }

        return scrolled;
    }

    private void load_settings () {
        mouse_settings = new Backend.MouseSettings ();
        touchpad_settings = new Backend.TouchpadSettings ();
    }

        /**
     *  Quit from the program.
     */
    public bool main_quit () {
        //save_window_position ();
        this.destroy ();

        return false;
    }

}