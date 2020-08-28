/*
 * Copyright (c) 2018 Enso Developers
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 */

public class DateTime.Plugin : Xfce.PanelPlugin {

  private Indicator indicator;
  private Gtk.ToggleButton app_button;

  public override void @construct() {

      var provider = new Gtk.CssProvider();
      provider.load_from_resource("/org/enso/datetime/application.css");
      Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
      Services.TimeManager.get_default ().minute_changed.connect (update_time);

      int x = 0, y = 0;
      app_button = new Gtk.ToggleButton ();
      //  app_button.get_style_context ().add_class ("clock");
      app_button.set_relief(Gtk.ReliefStyle.NONE);
      //app_button.set_focus_on_click(false);
      add (app_button);
      add_action_widget (app_button);

      update_time ();

      app_button.show ();
      indicator = new Indicator ();

      indicator.hide.connect (() => {
          app_button.active = false;
      });

      app_button.toggled.connect (() => {
        
        position_widget (indicator, null, out x, out y);
        indicator.move (x, y);

        if(app_button.active)
        {
          indicator.show_all ();
        }
        else {
          indicator.hide ();
        }
      });

      destroy.connect (() => { Gtk.main_quit (); });
  }

  private void update_time () {
    app_button.label = Services.TimeManager.get_default ().format (_("%a, %l:%M %P"));
  }
}

[ModuleInit]
public Type xfce_panel_module_init(TypeModule module) {
  return typeof (DateTime.Plugin);
}
