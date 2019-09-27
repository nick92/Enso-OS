/*
* Copyright (c) 2011-2017 elementary LLC (http://launchpad.net/pantheon-greeter)
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
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
*/

public class PowerLabel : Gtk.Grid {
    //  private Gtk.Button restart_button;
    //  private Gtk.Button shutdown_button;
    private Gtk.ListBox settings_list;
    private Gtk.EventBox eventbox_shutdown;
    private Gtk.EventBox eventbox_restart;
    private Gtk.EventBox eventbox_suspend;

    public PowerLabel () {
      this.add_events (Gdk.EventMask.BUTTON_PRESS_MASK
                | Gdk.EventMask.BUTTON_RELEASE_MASK
                | Gdk.EventMask.POINTER_MOTION_MASK);
    }

    construct {
      var settings = new Gtk.ToggleButton ();
      settings.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
      settings.get_style_context ().add_class ("power");
      settings.image = new Gtk.Image.from_resource ("/io/elementary/greeter/power.svg");
      settings.set_size_request (45, 45);
      settings.valign = Gtk.Align.CENTER;

      settings_list = new Gtk.ListBox ();
      settings_list.margin_bottom = 3;
      settings_list.margin_top = 3;

      var settings_popover = new Gtk.Popover (settings);
      //settings_popover.position = Gtk.PositionType.BOTTOM;
      settings_popover.add (settings_list);
      settings_popover.bind_property ("visible", settings, "active", GLib.BindingFlags.BIDIRECTIONAL);

      create_settings_items ();

      attach (settings, 0, 0, 1, 1);
      show_all ();
    }

    void create_settings_items () {
        var button = new Gtk.Label ("Shutdown");
        button.margin_left = 10;
        button.margin_right = 10;
        button.margin_top = 10;
        button.margin_bottom = 10;
        //button.reactive = true;

        eventbox_shutdown = new Gtk.EventBox();
        eventbox_shutdown.button_press_event.connect(shutdown_click);
        eventbox_shutdown.add(button);

        var button_row = new Gtk.ListBoxRow ();
        button_row.get_style_context ().add_class (Gtk.STYLE_CLASS_MENUITEM);
        button_row.add (eventbox_shutdown);
        settings_list.add (button_row);

        var button_restart = new Gtk.Label ("Restart");
        button_restart.margin_left = 10;
        button_restart.margin_top = 10;
        button_restart.margin_bottom = 10;
        button_restart.margin_right = 10;

        eventbox_restart = new Gtk.EventBox();
        eventbox_restart.button_press_event.connect(restart_click);
        eventbox_restart.add(button_restart);

        var button_row_restart = new Gtk.ListBoxRow ();
        button_row_restart.get_style_context ().add_class (Gtk.STYLE_CLASS_MENUITEM);
        button_row_restart.add (eventbox_restart);
        settings_list.add (button_row_restart);

        var button_suspend = new Gtk.Label ("Suspend");
        button_suspend.margin_left = 10;
        button_suspend.margin_top = 10;
        button_suspend.margin_bottom = 10;
        button_suspend.margin_right = 10;

        eventbox_suspend = new Gtk.EventBox();
        eventbox_suspend.button_press_event.connect(suspend_click);
        eventbox_suspend.add(button_suspend);

        var button_row_suspend = new Gtk.ListBoxRow ();
        button_row_suspend.get_style_context ().add_class (Gtk.STYLE_CLASS_MENUITEM);
        button_row_suspend.add (eventbox_suspend);
        settings_list.add (button_row_suspend);

        settings_list.show_all ();
    }

    bool shutdown_click (Gtk.Widget sender, Gdk.EventButton evt)
    {
      try{
        LightDM.shutdown ();
      }catch(GLib.Error error)
      {}

      return true;
    }

    bool restart_click (Gtk.Widget sender, Gdk.EventButton evt)
    {
      try{
        LightDM.restart ();
      }catch(GLib.Error error)
      {}

      return true;
    }

    bool suspend_click (Gtk.Widget sender, Gdk.EventButton evt)
    {
      try{
        LightDM.suspend ();
      }catch(GLib.Error error)
      {}

      return true;
    }

  }
