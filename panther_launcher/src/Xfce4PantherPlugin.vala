// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//
//  Copyright (C) 2011-2012 Panther Developers
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

namespace Panther {

  public class Plugin : Xfce.PanelPlugin {

    private Panther app;

    public PantherView view = null;
    public static bool silent = false;
    public static bool command_mode = false;
    public bool launched = false;

    public static Settings settings { get; private set; default = null; }
    public static Gtk.IconTheme icon_theme { get; set; default = null; }
    private DBusService? dbus_service = null;

    private int view_width;
    private int view_height;
    private bool first = true;

    private string[] args = null;

    public override void @construct() {

        Intl.bindtextdomain(Constants.GETTEXT_PACKAGE, GLib.Path.build_filename(Constants.DATADIR,"locale"));
        Intl.textdomain(Constants.GETTEXT_PACKAGE);
        Intl.bind_textdomain_codeset(Constants.GETTEXT_PACKAGE, "UTF-8" );

        app = new Panther ();
        app.view = new PantherView ();

        app.app_button = new Gtk.ToggleButton.with_label ("Applications");
        app.app_button.set_relief(Gtk.ReliefStyle.NONE);
        app.app_button.set_focus_on_click(false);
        add (app.app_button);
        app.app_button.show ();

        add_action_widget (app.app_button);

        Bus.own_name (BusType.SESSION, "com.rastersoft.panther.remotecontrol", BusNameOwnerFlags.NONE, on_bus_aquired, () => {}, () => {});

        app.app_button.toggled.connect (() => {
          if (app.app_button.active) {
            if (app.get_windows () == null) {
              app.run ();
            }
            else {
              app.view.show_panther ();
            }
          }
          else {
            app.view.hide ();
          }
        });

    		menu_show_about ();
    		about.connect (() => {
    				Gtk.show_about_dialog (null,
    					"program-name", "Panther Launcher",
    					"comments", "A fork from Slingshot Launcher. Its main change is that it doesn't depend on Gala, Granite or other libraries not available in regular linux distros. It also has been ported to Autovala, allowing an easier build. Finally, it also has an applet for Gnome Flashback and an extension for Gnome Shell, allowing to use it from these desktops.",
    					null);
    			});

    		destroy.connect (() => { Gtk.main_quit (); });
    }
  }
}

[ModuleInit]
public Type xfce_panel_module_init(TypeModule module) {
  return typeof (Panther.Plugin);
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
