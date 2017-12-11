// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//
//  Copyright (C) 2011-2012 Giulio Collura
//  Copyright (C) 2015 Raster Software Vigo
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

using Gtk;
using Gdk;
using GLib;

// project version = 1.12.0

Panther.Panther app;
//Panther.PantherView view;

public class Panther.Panther : Gtk.Application {

    public PantherView view = null;
    public static bool silent = false;
    public static bool command_mode = false;
    public bool launched = false;
    public Gtk.ToggleButton app_button;
    public TestClient client;

    public static Settings settings { get; private set; default = null; }
    public static Gtk.IconTheme icon_theme { get; set; default = null; }
    public DBusService? dbus_service = null;

    private int view_width;
    private int view_height;

    construct {
        application_id = "com.rastersoft.panther";
    }

    public int set_view_width {
      set {
        this.view_width = value;
      }
    }

    public int set_view_height {
      set {
        this.view_height = value;
      }
    }

    public Panther () {
        settings = new Settings ();
        Pixels.ITEM_SIZE = settings.icon_size * 2;
        Pixels.SIDEBAR_WIDTH = Pixels.PADDING + Pixels.ITEM_SIZE - Pixels.SIDEBAR_GRID_PADDING - 1;
    }

    public bool realize_view(Cairo.Context? cr) {

      Gtk.Allocation alloc;
      this.view.get_allocation(out alloc);
      if ((alloc.width != this.view_width) || (alloc.height != this.view_height)) {
          this.view_width = alloc.width;
          this.view_height = alloc.height;
          this.view.reposition();
      }
      return false;
    }

    protected override void activate () {
      if (this.get_windows () == null) {
          this.view_width = -1;
          this.view_height = -1;
          this.view = new PantherView ();
          this.view.set_application (this);
          this.view.draw.connect_after(this.realize_view);

          if (dbus_service == null)
              this.dbus_service = new DBusService (view);

          if (!Panther.silent) {
              this.view.show_panther ();
          }
      } else {
          if (this.view.visible && !Panther.silent) {
              this.view.hide ();
          } else {
              this.view.show_panther ();
          }
      }
      Panther.silent = false;
    }

    static const OptionEntry[] entries = {
        { "silent", 's', 0, OptionArg.NONE, ref silent, "Launch Panther as a background process without it appearing visually.", null },
        { "command-mode", 'c', 0, OptionArg.NONE, ref command_mode, "This feature is not implemented yet. When it is, description will be changed.", null },
        { null }
    };

    public static int main (string[] args) {

        Intl.bindtextdomain(Constants.GETTEXT_PACKAGE, GLib.Path.build_filename(Constants.DATADIR,"locale"));
        Intl.textdomain(Constants.GETTEXT_PACKAGE);
        Intl.bind_textdomain_codeset(Constants.GETTEXT_PACKAGE, "UTF-8" );

        if (args.length > 1) {
            var context = new OptionContext ("");
            context.add_main_entries (entries, "panther");
            context.add_group (Gtk.get_option_group (true));

            try {
                context.parse (ref args);
            } catch (Error e) {
                print (e.message + "\n");
            }

        }
        app = new Panther ();

        Bus.own_name (BusType.SESSION, "com.rastersoft.panther.remotecontrol", BusNameOwnerFlags.NONE, on_bus_aquired, () => {}, () => {});

        return app.run (args);
    }
}

void on_bus_aquired (DBusConnection conn) {
    try {
        conn.register_object ("/com/rastersoft/panther/remotecontrol", new RemoteControl ());
    } catch (IOError e) {
        GLib.stderr.printf ("Could not register service\n");
    }
}

[DBus (name = "com.rastersoft.panther.remotecontrol")]
public class RemoteControl : GLib.Object {

    public int do_ping(int v) {
        return (v+1);
    }

    public void do_show() {
        print("Called from DBus\n");
        app.activate();
    }
}
