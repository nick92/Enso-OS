// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//
//  Copyright (C) 2011-2012 Giulio Collura
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

using Gtk;

public class Panther.Widgets.AppEntry : Gtk.Button {
    private static Gtk.Menu menu;

    public Gtk.Label app_label;
    private Gdk.Pixbuf icon;
    private new Gtk.Image image;

    public string exec_name;
    public string app_name;
    public string desktop_id;
    public int icon_size;
    public string desktop_path;

    public File launchers_dir;

    public signal void app_launched ();

    private bool dragging = false; //prevent launching

    private Backend.App application;

    private Backend.AppSystem app_system;

#if HAS_PLANK
    static construct {
        plank_client = Plank.DBusClient.get_instance ();
    }

    private static Plank.DBusClient plank_client;
    private bool docked = false;
    private string desktop_uri;
#endif

    public AppEntry (Backend.App app) {
        Gtk.TargetEntry dnd = {"text/uri-list", 0, 0};
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, {dnd},
                             Gdk.DragAction.COPY);

        desktop_id = app.desktop_id;
        desktop_path = app.desktop_path;
#if HAS_PLANK
        desktop_uri = File.new_for_path (desktop_path).get_uri ();
#endif

        application = app;
        app_name = app.name;
        tooltip_text = app.description;
        exec_name = app.exec;
        icon_size = Panther.settings.icon_size;
        icon = app.icon;

        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        if (Panther.settings.font_size <= 0.001) {
            app_label = new Gtk.Label (app_name);
            app_label.use_markup = false;
        } else {
            var texto = "<span font_size=\"%d\">%s</span>".printf((int)(Panther.settings.font_size * 1000),app_name);
            app_label = new Gtk.Label(null);
            app_label.set_markup(texto);
        }

        app_label.halign = Gtk.Align.CENTER;
        app_label.justify = Gtk.Justification.CENTER;
        app_label.set_line_wrap (true);
        app_label.lines = 2;
        app_label.set_single_line_mode (false);
        app_label.set_ellipsize (Pango.EllipsizeMode.END);

        image = new Gtk.Image.from_pixbuf (icon);
        image.icon_size = icon_size;
        image.margin_top = 12;

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.row_spacing = 6;
        grid.expand = true;
        grid.halign = Gtk.Align.CENTER;
        grid.add (image);
        grid.add (app_label);

        add (grid);
        set_size_request (Pixels.ITEM_SIZE, Pixels.ITEM_SIZE);

        this.clicked.connect (launch_app);

        this.button_press_event.connect ((e) => {
            if (e.button != Gdk.BUTTON_SECONDARY)
                return false;

            create_menu ();
            if (menu != null && menu.get_children () != null) {
                menu.popup (null, null, null, e.button, e.time);
                return true;
            }
            return false;
        });

        this.drag_begin.connect ( (ctx) => {
            this.dragging = true;
            Gtk.drag_set_icon_pixbuf (ctx, icon, 0, 0);
        });

        this.drag_end.connect ( () => {
            this.dragging = false;
            var panther_app = (Gtk.Application) GLib.Application.get_default ();
            ((PantherView)panther_app.active_window).grab_device ();
        });

        this.drag_data_get.connect ( (ctx, sel, info, time) => {
            sel.set_uris ({File.new_for_path (desktop_path).get_uri ()});
        });

        app.icon_changed.connect (() => {
            icon = app.icon;
            image.set_from_pixbuf (icon);
        });

    }

    public override void get_preferred_width (out int minimum_width, out int natural_width) {
        minimum_width = Pixels.ITEM_SIZE;
        natural_width = Pixels.ITEM_SIZE;
    }

    public override void get_preferred_height (out int minimum_height, out int natural_height) {
        minimum_height = Pixels.ITEM_SIZE;
        natural_height = Pixels.ITEM_SIZE;
    }

    public void launch_app () {
        application.launch ();
        app_launched ();
    }

    private void create_menu () {
        // Display the apps static quicklist items in a popover menu
        if (application.actions == null) {
            try {
                application.init_actions ();
            } catch (KeyFileError e) {
                critical ("%s: %s", desktop_path, e.message);
            }
        }

        menu = new Gtk.Menu ();

        // Showing a menu reverts the effect of the grab_device function.
        menu.hide.connect (() => {
            var panther_app = (Gtk.Application) GLib.Application.get_default ();
            ((PantherView)panther_app.active_window).grab_device ();
        });
        foreach (var action in application.actions) {
            var menuitem = new Gtk.MenuItem.with_mnemonic (action);
            menu.add (menuitem);
            menuitem.activate.connect (() => {
                try {
                    var values = application.actions_map.get (action).split (";;");
                    AppInfo.create_from_commandline (values[0], null, AppInfoCreateFlags.NONE).launch (null, null);
                    app_launched ();
                } catch (Error e) {
                    critical ("%s: %s", desktop_path, e.message);
                }
            });
        }

        if (menu.get_children ().length () > 0)
            menu.add (new Gtk.SeparatorMenuItem ());

        menu.add(get_saved_menuitem ());

#if HAS_PLANK
        if (plank_client != null && plank_client.is_connected) {
            if (menu.get_children ().length () > 0)
                menu.add (new Gtk.SeparatorMenuItem ());

            menu.add (get_plank_menuitem ());
        }
        else {
          message("Not connected: " + plank_client.is_connected.to_string ());
        }
#endif

        menu.show_all ();
    }

#if HAS_PLANK
    private Gtk.MenuItem get_plank_menuitem () {
        docked = (desktop_uri in plank_client.get_persistent_applications ());

        var plank_menuitem = new Gtk.MenuItem ();
        plank_menuitem.set_use_underline (true);

        if (docked)
            plank_menuitem.set_label (_("Remove from _Dock"));
        else
            plank_menuitem.set_label (_("Pin to _Dock"));

        plank_menuitem.activate.connect (plank_menuitem_activate);

        return plank_menuitem;
    }

    private void plank_menuitem_activate () {
        if (plank_client == null || !plank_client.is_connected)
            return;

        if (docked)
            plank_client.remove_item (desktop_uri);
        else
            plank_client.add_item (desktop_uri);
    }
#endif
  private Gtk.MenuItem get_saved_menuitem () {
      //docked = (desktop_uri in plank_client.get_persistent_applications ());
      var panther_app = (Gtk.Application) GLib.Application.get_default ();
      bool saved = ((PantherView)panther_app.active_window).cat_saved;

      var saved_menuitem = new Gtk.MenuItem ();
      saved_menuitem.set_use_underline (true);

      warning(desktop_uri);

      if (saved)
          saved_menuitem.set_label (_("Remove from _Saved"));
      else
          saved_menuitem.set_label (_("Add to Saved"));

      saved_menuitem.activate.connect (saved_menuitem_activate);

      return saved_menuitem;
  }

  private void saved_menuitem_activate () {
    var panther_app = (Gtk.Application) GLib.Application.get_default ();
    bool saved = ((PantherView)panther_app.active_window).cat_saved;

    if(saved)
      remove_saved_item ();
    else
      add_saved_item ();
  }

  private void add_saved_item () {
    string uri = desktop_uri;
    File? target_dir = null;

    if (target_dir == null)
    {
      target_dir = File.new_for_path (Environment.get_user_config_dir () + "/panther/saved/");

      if (!target_dir.query_exists ())
				try {
					target_dir.make_directory_with_parents ();
				} catch (Error e) {
					critical ("Could not access or create the directory '%s'. (%s)", target_dir.get_path () ?? "", e.message);
				}
    }

    bool is_valid = false;
    string basename;
    var launcher_file = File.new_for_uri (uri);
    is_valid = launcher_file.query_exists ();
    basename = (launcher_file.get_basename () ?? "unknown");

    if (is_valid) {
      var file = new KeyFile ();

      try {
        // find a unique file name, based on the name of the launcher
        var index_of_last_dot = basename.last_index_of (".");
        var launcher_base = (index_of_last_dot >= 0 ? basename.slice (0, index_of_last_dot) : basename);
        var dockitem = "%s.saveditem".printf (launcher_base);
        var dockitem_file = target_dir.get_child (dockitem);

        var counter = 1;

        if (!dockitem_file.query_exists ()) {
          // save the key file
          var stream = new DataOutputStream (dockitem_file.create (FileCreateFlags.NONE));
          stream.put_string (file.to_data ());
          stream.close ();

          var panther_app = (Gtk.Application) GLib.Application.get_default ();
          ((PantherView)panther_app.active_window).add_saved (basename);
        }
      } catch (Error e){
        warning(e.message);
      }
    }
  }

  private void remove_saved_item () {
    string uri = desktop_uri;
    File? target_dir = null;
    File saved_file = null;

    if (target_dir == null)
      target_dir = File.new_for_path (Environment.get_home_dir () + "/.config/panther/saved/");

    bool is_valid = false;
    string basename;
    var launcher_file = File.new_for_uri (uri);
    //is_valid = launcher_file.query_exists ();
    basename = (launcher_file.get_basename () ?? "unknown");

    var saveditem = "%s%s.saveditem".printf (target_dir.get_path () + "/", basename.substring(0, basename.length - 8));
    message("removing saved file: " + saveditem);
    saved_file = File.new_for_path(saveditem);
    is_valid = saved_file.query_exists ();

    if(is_valid){
      try{
        saved_file.delete ();

        var panther_app = (Gtk.Application) GLib.Application.get_default ();
        ((PantherView)panther_app.active_window).add_saved (basename);

      } catch (Error e){
        warning(e.message);
      }
    }
  }
}
