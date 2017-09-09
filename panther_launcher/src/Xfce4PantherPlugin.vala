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

[DBus (name = "com.rastersoft.panther")]
interface Panther_Service : Object {
  public signal void visibility_changed (bool launcher_visible);
}

Gtk.ToggleButton app_button;

namespace Panther {

  public class Plugin : Xfce.PanelPlugin {

    //private Panther app;

    //public PantherView view = null;
    public static bool silent = false;
    public static bool command_mode = false;
    public bool launched = false;

    public static Settings settings { get; private set; default = null; }
    public static Gtk.IconTheme icon_theme { get; set; default = null; }
    //private Gtk.ToggleButton app_button;

    private int view_width;
    private int view_height;
    private bool first = true;

    private Panther_Service panther_bus;

    public override void @construct() {

        app_button = new Gtk.ToggleButton.with_label ("Applications");
        app_button.set_relief(Gtk.ReliefStyle.NONE);
        //app_button.set_focus_on_click(false);
        add (app_button);
        add_action_widget (app_button);

        app_button.show ();

        panther_bus = Bus.get_proxy_sync (BusType.SESSION, "com.rastersoft.panther",
                                                        "/com/rastersoft/panther");

        app_button.toggled.connect (() => {
          if (app_button.active) {
              try {
      					Process.spawn_command_line_async ("panther_launcher");
                //remote_bus.do_show ();
      				} catch (Error e) {
      					warning (e.message);
      				}
            }
        });

        try{
          panther_bus.visibility_changed.connect ((visible) => {
              if(!visible)
                app_button.set_active(visible);
              else {
                //app_button.set_active(visible);
              }
          });
        } catch (Error e) {
          warning (e.message);
        }

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
