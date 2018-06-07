/***

    Copyright (C) 2017 Tranquil Developers

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

public class Pantheon.Keyboard.PlugWindow : Gtk.Window {

  Gtk.Grid  grid;
  Gtk.Stack stack;

  public PlugWindow () {
    // Set up geometry
    Gdk.Geometry geo = new Gdk.Geometry();
    geo.min_width = 400;
    geo.min_height = 500;
    geo.max_width = 1024;
    geo.max_height = 2048;

    this.set_geometry_hints(null, geo, Gdk.WindowHints.MIN_SIZE | Gdk.WindowHints.MAX_SIZE);
    this.set_title("Keyboard Settings");
    this.add(get_widget ());
  }

  public Gtk.Widget get_widget () {
      if (grid == null) {
          grid = new Gtk.Grid ();
          grid.margin = 12;
          stack = new Gtk.Stack ();
          var stack_switcher = new Gtk.StackSwitcher ();
          stack_switcher.set_stack (stack);
          stack_switcher.halign = Gtk.Align.CENTER;

          stack.add_titled (new Keyboard.LayoutPage.Page (), "layout", _("Layout"));
          stack.add_titled (new Keyboard.Shortcuts.Page (), "shortcuts", _("Shortcuts"));
          stack.add_titled (new Keyboard.Behaviour.Page (), "behavior", _("Behavior"));

          grid.attach (stack_switcher, 0, 0, 1, 1);
          grid.attach (stack, 0, 1, 1, 1);
      }
      grid.show_all ();
      return grid;
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
