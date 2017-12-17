/*-
 * Copyright (c) 2015-2016 elementary LLC.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

// Helper class for the file IO functions we'll need
// Not needed at all, but helpful for organization
public class IOHelper : GLib.Object {
    private const string[] ACCEPTED_TYPES = {
        "image/jpeg",
        "image/png",
        "image/tiff",
        "image/svg+xml",
        "image/gif"
    };

    // Check if the filename has a picture file extension.
    public static bool is_valid_file_type (GLib.FileInfo file_info) {
        // Check for correct file type, don't try to load directories and such
        if (file_info.get_file_type () != GLib.FileType.REGULAR) {
            return false;
        }

        foreach (var type in ACCEPTED_TYPES) {
            if (GLib.ContentType.equals (file_info.get_content_type (), type)) {
                return true;
            }
        }

        return false;
    }

    // Quickly count up all of the valid wallpapers in the wallpaper folder.
    public static int count_wallpapers (GLib.File wallpaper_folder) {
        GLib.FileInfo file_info = null;
        int count = 0;

        try {
            // Get an enumerator for all of the plain old files in the wallpaper folder.
            var enumerator = wallpaper_folder.enumerate_children (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE, 0);

            while ((file_info = enumerator.next_file ()) != null) {
                if (is_valid_file_type(file_info)) {
                    count++;
                }
            }
        } catch(GLib.Error err) {
            if (!(err is IOError.NOT_FOUND)) {
                warning ("Could not pre-scan wallpaper folder. Progress percentage may be off: %s", err.message);
            }
        }

        return count;
    }
}

public enum ColumnType {
    ICON,
    NAME
}

[DBus (name = "org.freedesktop.Accounts.User")]
interface AccountsServiceUser : Object {
    public abstract void set_background_file (string filename) throws IOError;
}

public class Wallpaper : Gtk.Grid {
    // name of the default-wallpaper-link that we can prevent loading it again
    // (assumes that the defaultwallpaper is also in the system wallpaper directory)
    static string DEFAULT_LINK = "file://%s/elementaryos-default".printf (SYSTEM_BACKGROUNDS_PATH);
    const string SYSTEM_BACKGROUNDS_PATH = "/usr/share/backgrounds";

    //public Switchboard.Plug plug { get; construct set; }
    private GLib.Settings settings;

    //Instance of the AccountsServices-Interface for this user
    private AccountsServiceUser accountsservice = null;

    private Gtk.FlowBox wallpaper_view;
    private Gtk.ComboBoxText combo;
    private Gtk.ComboBoxText folder_combo;
    private Gtk.ColorButton color_button;

    private WallpaperContainer active_wallpaper = null;
    private SolidColorContainer solid_color = null;

    private Cancellable last_cancellable;

    private string current_wallpaper_path;
    private bool prevent_update_mode = false; // When restoring the combo state, don't trigger the update.
    public bool finished; //shows that we got or wallpapers together

    public Wallpaper () {
      settings = new GLib.Settings ("org.gnome.desktop.background");

      //DBus connection needed in update_wallpaper for
      //passing the wallpaper-information to accountsservice.
       try {
          string uid = "%d".printf ((int) Posix.getuid ());
          accountsservice = Bus.get_proxy_sync (BusType.SYSTEM,
                  "org.freedesktop.Accounts",
                  "/org/freedesktop/Accounts/User" + uid);
      } catch (Error e) {
          warning (e.message);
      }

      var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

      wallpaper_view = new Gtk.FlowBox ();
      wallpaper_view.activate_on_single_click = true;
      wallpaper_view.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
      wallpaper_view.homogeneous = true;
      wallpaper_view.selection_mode = Gtk.SelectionMode.SINGLE;
      wallpaper_view.child_activated.connect (update_checked_wallpaper);

      var color = settings.get_string ("primary-color");
      create_solid_color_container (color);

      Gtk.TargetEntry e = {"text/uri-list", 0, 0};
      wallpaper_view.drag_data_received.connect (on_drag_data_received);
      Gtk.drag_dest_set (wallpaper_view, Gtk.DestDefaults.ALL, {e}, Gdk.DragAction.COPY);

      var scrolled = new Gtk.ScrolledWindow (null, null);
      scrolled.expand = true;
      scrolled.add (wallpaper_view);

      folder_combo = new Gtk.ComboBoxText ();
      folder_combo.margin = 12;
      folder_combo.append ("pic", _("Pictures"));
      folder_combo.append ("sys", _("Backgrounds"));
      folder_combo.append ("cus", _("Custom…"));
      folder_combo.changed.connect (update_wallpaper_folder);
      folder_combo.set_active (1);

      combo = new Gtk.ComboBoxText ();
      combo.valign = Gtk.Align.CENTER;
      combo.append ("centered", _("Centered"));
      combo.append ("zoom", _("Zoom"));
      combo.append ("spanned", _("Spanned"));
      combo.changed.connect (update_mode);

      Gdk.RGBA rgba_color = {};
      if (!rgba_color.parse (color)) {
          rgba_color = { 1, 1, 1, 1 };
      }

      color_button = new Gtk.ColorButton ();
      color_button.margin = 12;
      color_button.margin_left = 0;
      color_button.rgba = rgba_color;
      color_button.color_set.connect (update_color);

      var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
      size_group.add_widget (combo);
      size_group.add_widget (color_button);
      size_group.add_widget (folder_combo);

      load_settings ();

      var actionbar = new Gtk.ActionBar ();
      actionbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
      actionbar.add (folder_combo);
      actionbar.pack_end (color_button);
      actionbar.pack_end (combo);

      attach (separator, 0, 0, 1, 1);
      attach (scrolled, 0, 1, 1, 1);
      attach (actionbar, 0, 2, 1, 1);
    }


    private void load_settings () {
        // TODO: need to store the previous state, before changing to none
        // when a solid color is selected, because the combobox doesn't know
        // about it anymore. The previous state should be loaded instead here.
        string picture_options = settings.get_string ("picture-options");
        if (picture_options == "none") {
            combo.set_sensitive (false);
            picture_options = "zoom";
        }
        prevent_update_mode = true;
        combo.set_active_id (picture_options);

        current_wallpaper_path = settings.get_string ("picture-uri");
    }

    /*
     * We pass the path to accountsservices that the login-screen can
     * see what background we selected. This is right now just a patched-in functionality of
     * accountsservice, so we expect that it is maybe not there
     * and do nothing if we encounter a unpatched accountsservices-backend.
    */
    private void update_accountsservice () {
        try {
            var file = File.new_for_uri (current_wallpaper_path);
            string uri = file.get_uri ();
            string path = file.get_path ();

            if (!path.has_prefix (SYSTEM_BACKGROUNDS_PATH) && !path.has_prefix (get_local_bg_location ())) {
                var localfile = copy_for_library (file);
                if (localfile != null) {
                    uri = localfile.get_uri ();
                }
            }

            var greeter_file = copy_for_greeter (file);
            if (greeter_file != null) {
                path = greeter_file.get_path ();
            }

            settings.set_string ("picture-uri", uri);
            accountsservice.set_background_file (path);
        } catch (Error e) {
            warning (e.message);
        }
    }

    private void update_checked_wallpaper (Gtk.FlowBox box, Gtk.FlowBoxChild child) {
        var children = (WallpaperContainer) wallpaper_view.get_selected_children ().data;

        if (!(children is SolidColorContainer)) {
            current_wallpaper_path = children.uri;
            update_accountsservice ();

            if (active_wallpaper == solid_color) {
                combo.set_sensitive (true);
                settings.set_string ("picture-options", combo.get_active_id ());
            }

        } else {
            set_combo_disabled_if_necessary ();
            settings.set_string ("primary-color", solid_color.color);
        }

        children.checked = true;

        if (active_wallpaper != null) {
            active_wallpaper.checked = false;
        }

        active_wallpaper = children;
    }

    private void update_color () {
        if (finished) {
            set_combo_disabled_if_necessary ();
            create_solid_color_container (color_button.rgba.to_string ());
            wallpaper_view.add (solid_color);
            wallpaper_view.select_child (solid_color);

            if (active_wallpaper != null) {
                active_wallpaper.checked = false;
            }

            active_wallpaper = solid_color;
            active_wallpaper.checked = true;
            settings.set_string ("primary-color", solid_color.color);
        }
    }

    private void update_mode () {
        if (!prevent_update_mode) {
            settings.set_string ("picture-options", combo.get_active_id ());

            // Changing the mode, while a solid color is selected, change focus to the
            // wallpaper tile.
            if (active_wallpaper == solid_color) {
                active_wallpaper.checked = false;

                foreach (var child in wallpaper_view.get_children ()) {
                    var container = (WallpaperContainer) child;
                    if (container.uri == current_wallpaper_path) {
                        container.checked = true;
                        wallpaper_view.select_child (container);
                        active_wallpaper = container;
                        break;
                    }
                }
            }
        } else {
            prevent_update_mode = false;
        }
    }

    private void set_combo_disabled_if_necessary () {
        if (active_wallpaper != solid_color) {
            combo.set_sensitive (false);
            settings.set_string ("picture-options", "none");
        }
    }

    private void update_wallpaper_folder () {
        if (last_cancellable != null)
            last_cancellable.cancel ();

        var cancellable = new Cancellable ();
        last_cancellable = cancellable;
        if (folder_combo.get_active () == 0) {
            clean_wallpapers ();
            var picture_dir = GLib.File.new_for_path (GLib.Environment.get_user_special_dir (GLib.UserDirectory.PICTURES));
            load_wallpapers.begin (picture_dir.get_uri (), cancellable);
        } else if (folder_combo.get_active () == 1) {
            clean_wallpapers ();

            var system_uri = "file://" + SYSTEM_BACKGROUNDS_PATH;
            var user_uri = GLib.File.new_for_path (get_local_bg_location ()).get_uri ();

            load_wallpapers.begin (system_uri, cancellable);
            load_wallpapers.begin (user_uri, cancellable);
        } else if (folder_combo.get_active () == 2) {
            var dialog = new Gtk.FileChooserDialog (_("Select a folder"), null, Gtk.FileChooserAction.SELECT_FOLDER);
            dialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
            dialog.add_button (_("Open"), Gtk.ResponseType.ACCEPT);
            dialog.set_default_response (Gtk.ResponseType.ACCEPT);

            if (dialog.run () == Gtk.ResponseType.ACCEPT) {
                clean_wallpapers ();
                load_wallpapers.begin (dialog.get_file ().get_uri (), cancellable);
                dialog.destroy ();
            } else {
                dialog.destroy ();
            }
        }
    }

    private async void load_wallpapers (string basefolder, Cancellable cancellable) {
        if (cancellable.is_cancelled () == true) {
            return;
        }

        folder_combo.set_sensitive (false);

        var directory = File.new_for_uri (basefolder);

        // The number of wallpapers we've added so far
        double done = 0.0;

        try {
            // Count the # of wallpapers
            int count = IOHelper.count_wallpapers(directory);
            if (count == 0) {
                folder_combo.set_sensitive (true);
            }

            // Enumerator object that will let us read through the wallpapers asynchronously
            var e = yield directory.enumerate_children_async (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE, 0, Priority.DEFAULT);

            while (true) {
                if (cancellable.is_cancelled () == true) {
                    return;
                }
                // Grab a batch of 10 wallpapers
                var files = yield e.next_files_async (10, Priority.DEFAULT);
                // Stop the loop if we've run out of wallpapers
                if (files == null) {
                    break;
                }

                // Loop through and add each wallpaper in the batch
                foreach (var info in files) {
                    if (cancellable.is_cancelled () == true) {
                        return;
                    }
                    // We're going to add another wallpaper
                    done++;

                    if (info.get_file_type () == FileType.DIRECTORY) {
                        // Spawn off another loader for the subdirectory
                        load_wallpapers.begin (basefolder + "/" + info.get_name (), cancellable);
                        continue;
                    } else if (!IOHelper.is_valid_file_type (info)) {
                        // Skip non-picture files
                        continue;
                    }

                    var file = File.new_for_uri (basefolder + "/" + info.get_name ());
                    string uri = file.get_uri ();

                    // Skip the default_wallpaper as seen in the description of the
                    // default_link variable
                    if (uri == DEFAULT_LINK) {
                        continue;
                    }

                    var wallpaper = new WallpaperContainer (uri);
                    wallpaper_view.add (wallpaper);
                    wallpaper.show_all ();

                    // Select the wallpaper if it is the current wallpaper
                    if (current_wallpaper_path.has_suffix (uri) && settings.get_string ("picture-options") != "none") {
                        this.wallpaper_view.select_child (wallpaper);
                        //set the widget activated without activating it
                        wallpaper.checked = true;
                        active_wallpaper = wallpaper;
                    }

                    // Have GTK update the UI even while we're busy
                    // working on file IO.
                    while(Gtk.events_pending ()) {
                        Gtk.main_iteration();
                    }
                }
            }

            finished = true;

            if (solid_color == null) {
                create_solid_color_container (color_button.rgba.to_string ());
            } else {
                // Ugly workaround to keep the solid color last, because currently
                // load_wallpapers is running async, recursively. Just let each of them
                // add / remove the tile until it's settled.
                wallpaper_view.remove (solid_color);
            }

            wallpaper_view.add (solid_color);
            if (settings.get_string ("picture-options") == "none") {
                wallpaper_view.select_child (solid_color);
                solid_color.checked = true;
                active_wallpaper = solid_color;
            }

            folder_combo.set_sensitive (true);

        } catch (Error err) {
            if (!(err is IOError.NOT_FOUND)) {
                warning (err.message);
            }
        }
    }

    private void create_solid_color_container (string color) {
        if (solid_color != null) {
            wallpaper_view.unselect_child (solid_color);
            wallpaper_view.remove (solid_color);
            solid_color.destroy ();
        }

        solid_color = new SolidColorContainer (color);
        solid_color.show_all ();
    }

    private void clean_wallpapers () {
        foreach (var child in wallpaper_view.get_children ()) {
            child.destroy ();
        }

        solid_color = null;
        //reduce memory usage and prevent to load old thumbnail
        Cache.clear ();
    }

    private string get_local_bg_location () {
        return Path.build_filename (Environment.get_user_data_dir (), "backgrounds") + "/";
    }

    private File? copy_for_library (File source) {
        File? dest = null;

        try {
            File folder = File.new_for_path (get_local_bg_location ());
            folder.make_directory_with_parents ();
        } catch (Error e) {
            if (e is GLib.IOError.EXISTS) {
                debug ("Local background directory already exists");
            } else {
                warning (e.message);
            }
        }

        try {
            dest = File.new_for_path (get_local_bg_location () + source.get_basename ());
            source.copy (dest, FileCopyFlags.OVERWRITE | FileCopyFlags.ALL_METADATA);
        } catch (Error e) {
            warning ("%s\n", e.message);
        }

        return dest;
    }

    private File? copy_for_greeter (File source) {
        File? dest = null;
        try {
            string greeter_data_dir = Path.build_filename (Environment.get_variable ("XDG_GREETER_DATA_DIR"), "wallpaper");
            if (greeter_data_dir == "") {
                greeter_data_dir = Path.build_filename ("/var/lib/lightdm-data/", Environment.get_user_name (), "wallpaper");
            }

            var folder = File.new_for_path (greeter_data_dir);
            if (folder.query_exists ()) {
                var enumerator = folder.enumerate_children ("standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
                FileInfo? info = null;
                while ((info = enumerator.next_file ()) != null) {
                    enumerator.get_child (info).@delete ();
                }
            } else {
                folder.make_directory_with_parents ();
            }

            dest = File.new_for_path (Path.build_filename (greeter_data_dir, source.get_basename ()));
            source.copy (dest, FileCopyFlags.OVERWRITE | FileCopyFlags.ALL_METADATA);
        } catch (Error e) {
            warning ("%s\n", e.message);
            return null;
        }

        return dest;
    }

    private void on_drag_data_received (Gtk.Widget widget, Gdk.DragContext ctx, int x, int y, Gtk.SelectionData sel, uint information, uint timestamp) {
        if (sel.get_length () > 0) {
            try {
                File file = File.new_for_uri (sel.get_uris ()[0]);
                var info = file.query_info (FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE, 0);

                if (!IOHelper.is_valid_file_type (info)) {
                    Gtk.drag_finish (ctx, false, false, timestamp);
                    return;
                }

                string local_uri = file.get_uri ();
                var dest = copy_for_library (file);
                if (dest != null) {
                    local_uri = dest.get_uri ();
                }

                // Add the wallpaper name and thumbnail to the IconView
                var wallpaper = new WallpaperContainer (local_uri);
                wallpaper_view.add (wallpaper);
                wallpaper.show_all ();

                Gtk.drag_finish (ctx, true, false, timestamp);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }

            return;
        }

        Gtk.drag_finish (ctx, false, false, timestamp);
        return;
    }
}
