/*
* Copyright (c) 2017 elementary LLC. (https://github.com/elementary/switchboard-plug-pantheon-shell)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

namespace SetWallpaperContractor {
    const int DEFAULT_TRANSITION_DURATION = 1;
    const string SLIDESHOW_FILENAME = "slideshow.xml";

    const string SLIDESHOW_TEMPLATE = """
    <background>
        %s
    </background>""";

    const string SLIDESHOW_WALLPAPER_TEMPLATE = """
        <static>
            <duration>%i</duration>
            <file>%s</file>
        </static>
        <transition>
            <duration>%i</duration>
            <from>%s</from>
            <to>%s</to>
        </transition>
    """;

    const string SYSTEM_BACKGROUNDS_PATH = "/usr/share/backgrounds";

    private int delay_value = 60;

    [DBus (name = "org.freedesktop.Accounts.User")]
    interface AccountsServiceUser : Object {
        public abstract void set_background_file (string filename) throws IOError;
    }

    private void update_slideshow (string path, List<File> files, int duration) {
        var wallpapers = "";
        var len = files.length ();
        for (var i = 0; i < len; i++) {
            var slide = files.nth_data (i).get_path ();
            var next_slide = files.nth_data (i - 1 == len ? 0 : i).get_path ();

            wallpapers += SLIDESHOW_WALLPAPER_TEMPLATE.printf (duration, slide,
                DEFAULT_TRANSITION_DURATION, slide, next_slide);
        }

        var slideshow = SLIDESHOW_TEMPLATE.printf (wallpapers);

        try {
            FileUtils.set_contents (path, slideshow);
        } catch (Error e) {
            error (e.message);
        }

        set_settings_key ("file://" + path);
    }

    private void set_settings_key (string uri) {
        var settings = new Settings ("org.gnome.desktop.background");
        settings.set_string ("picture-uri", uri);
        settings.apply ();
        Settings.sync ();
    }

    private void delay_value_changed (Gtk.Scale duration_scale, Gtk.Label duration_label) {
        double value = duration_scale.adjustment.value;

        // f(x)=x^5 allows to have fine-grained values (seconds) to the left
        // and very coarse-grained values (hours) to the right of the slider.
        // We limit maximum value to 1 day and minimum to 5 seconds.
        delay_value = (int) (Math.pow (value, 5) / Math.pow (90, 5) * 60 * 60 * 24 + 5);

        // convert to text and remove fractions from values > 1 minute
        string text;
        if (delay_value < 60) {
            text = ngettext ("%d second", "%d seconds", delay_value).printf (delay_value);
        } else if (delay_value < 60 * 60) {
            int minutes = delay_value / 60;
            text = ngettext ("%d minute", "%d minutes", minutes).printf (minutes);
            delay_value = minutes * 60;
        } else if (delay_value < 60 * 60 * 24) {
            int hours = delay_value / (60 * 60);
            text = ngettext ("%d hour", "%d hours", hours).printf (hours);
            delay_value = hours * (60 * 60);
        } else {
            text = _("1 day");
            delay_value = 60 * 60 * 24;
        }

        duration_label.set_markup (_("Show each photo for") + " <b>" + text + "</b>");
    }

    private string get_local_bg_location () {
        return Path.build_filename (Environment.get_user_data_dir (), "backgrounds") + "/";
    }

    private File ensure_local_bg_exists () {
        var folder = File.new_for_path (get_local_bg_location ());
        if (!folder.query_exists ()) {
            try {
                folder.make_directory_with_parents ();
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        }

        return folder;
    }

    private File? copy_for_library (File source) {
        File? dest = null;

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

    public static int main (string[] args) {
        Gtk.init (ref args);

        AccountsServiceUser? accounts_service = null;
        try {
            string uid = "%d".printf ((int) Posix.getuid ());
            accounts_service = Bus.get_proxy_sync (BusType.SYSTEM,
                    "org.freedesktop.Accounts",
                    "/org/freedesktop/Accounts/User" + uid);
        } catch (Error e) {
            warning ("%s\n", e.message); 
        }

        var folder = ensure_local_bg_exists ();
        var files = new List<File> ();
        for (var i = 1; i < args.length; i++) {
            var file = File.new_for_path (args[i]);

            if (file != null) {

                string path = file.get_path ();
                File append_file = file;
                if (!path.has_prefix (SYSTEM_BACKGROUNDS_PATH) && !path.has_prefix (get_local_bg_location ())) {
                    var local_file = copy_for_library (file);
                    if (local_file != null) {
                        append_file = local_file;
                    }
                }

                files.append (append_file);

                var greeter_file = copy_for_greeter (file);
                if (greeter_file != null) {
                    path = greeter_file.get_path ();
                }

                try {
                    accounts_service.set_background_file (path);
                } catch (Error e) {
                    warning ("%s\n", e.message);
                }        
            }
        }

        if (files.length () < 1) {
            warning ("No images specified, aborting.\n");
            return 1;
        }

        if (files.length () == 1) {
            set_settings_key (files.data.get_uri ());
            return 0;
        }

        var dialog = new Gtk.Dialog.with_buttons (_("Set As Desktop Slideshow"), null, 0);
        dialog.deletable = false;

        dialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        dialog.add_button (_("Create slideshow"), Gtk.ResponseType.OK);

        var icon = new Gtk.Image.from_icon_name ("preferences-desktop-wallpaper", Gtk.IconSize.DIALOG);

        var title = new Gtk.Label (_("Set As Desktop Slideshow"));
        title.get_style_context ().add_class ("primary");
        title.xalign = 0;

        var label = new Gtk.Label ("");
        label.xalign = 0;

        var duration = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 10);
        duration.draw_value = false;
        duration.hexpand = true;
        duration.value_changed.connect (() => delay_value_changed (duration, label));
        duration.set_value (50);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.row_spacing = 6;
        grid.margin = 12;
        grid.margin_top = 0;
        grid.attach (icon, 0, 0, 1, 2);
        grid.attach (title, 1, 0, 1, 1);
        grid.attach (label, 1, 1, 1, 1);
        grid.attach (duration, 1, 2, 1, 1);

        dialog.set_default_response (Gtk.ResponseType.OK);
        dialog.get_content_area ().add (grid);
        dialog.get_action_area ().margin = 4;
        dialog.show_all ();

        if (dialog.run () == Gtk.ResponseType.OK) {
            dialog.destroy ();

            var path = folder.get_child (SLIDESHOW_FILENAME).get_path ();
            update_slideshow (path, files, delay_value);
            return 0;
        }

        return 1;
    }
}
