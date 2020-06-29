/*
* Copyright (c) 2016 elementary LLC. (https://elementary.io)
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
* Boston, MA 02110-1301 USA
*/

public class Dock : Gtk.Grid {
    private Gtk.Label primary_monitor_label;
    private Gtk.Switch primary_monitor;
    private Gtk.Label monitor_label;
    private Gtk.ComboBoxText monitor;
    private Plank.DockPreferences dock_preferences;

    construct {
        column_spacing = 12;
        halign = Gtk.Align.CENTER;
        row_spacing = 12;
        margin_start = margin_end = 6;

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/io/elementary/switchboard/plug/pantheon-shell");

        var icon_size_32 = new Gtk.RadioButton (null);
        icon_size_32.image = new Gtk.Image.from_icon_name ("application-default-icon-symbolic", Gtk.IconSize.DND);
        icon_size_32.tooltip_text = _("Small");

        var icon_size_48 = new Gtk.RadioButton.from_widget (icon_size_32);
        icon_size_48.image = new Gtk.Image.from_icon_name ("application-default-icon-symbolic", Gtk.IconSize.DIALOG);
        icon_size_48.tooltip_text = _("Default");

        var image_64 = new Gtk.Image ();
        image_64.icon_name = "application-default-icon-symbolic";
        image_64.pixel_size = 64;

        var icon_size_64 = new Gtk.RadioButton.from_widget (icon_size_32);
        icon_size_64.image = image_64;
        icon_size_64.tooltip_text = _("Large");

        var icon_size_unsupported = new Gtk.RadioButton.from_widget (icon_size_32);

        var icon_size_grid = new Gtk.Grid ();
        icon_size_grid.column_spacing = 24;
        icon_size_grid.add (icon_size_32);
        icon_size_grid.add (icon_size_48);
        icon_size_grid.add (icon_size_64);

        Plank.Paths.initialize ("plank", Constants.PLANKDATADIR);
        dock_preferences = new Plank.DockPreferences ("dock1");

        var pressure_switch = new Gtk.Switch ();
        pressure_switch.halign = Gtk.Align.START;
        pressure_switch.valign = Gtk.Align.CENTER;

        dock_preferences.bind_property ("PressureReveal", pressure_switch, "active", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.BIDIRECTIONAL);

        var hide_mode = new Gtk.ComboBoxText ();
        hide_mode.append_text (_("Focused window is maximized"));
        hide_mode.append_text (_("Focused window overlaps the dock"));
        hide_mode.append_text (_("Any window overlaps the dock"));
        hide_mode.append_text (_("Not being used"));

        Plank.HideType[] hide_mode_ids = {Plank.HideType.DODGE_MAXIMIZED, Plank.HideType.INTELLIGENT, Plank.HideType.WINDOW_DODGE, Plank.HideType.AUTO};

        var hide_switch = new Gtk.Switch ();
        hide_switch.halign = Gtk.Align.START;
        hide_switch.valign = Gtk.Align.CENTER;

        var hide_none = (dock_preferences.HideMode != Plank.HideType.NONE);
        hide_switch.active = hide_none;
        if (hide_none) {
            for (int i = 0; i < hide_mode_ids.length; i++) {
                if (hide_mode_ids[i] == dock_preferences.HideMode)
                    hide_mode.active = i;
            }
        } else {
            hide_mode.sensitive = false;
        }

        hide_mode.changed.connect (() => {
            dock_preferences.HideMode = hide_mode_ids[hide_mode.active];
        });

        hide_switch.bind_property ("active", pressure_switch, "sensitive", BindingFlags.DEFAULT);
        hide_switch.bind_property ("active", hide_mode, "sensitive", BindingFlags.DEFAULT);

        hide_switch.notify["active"].connect (() => {
            if (hide_switch.active) {
                dock_preferences.HideMode = hide_mode_ids[hide_mode.active];
            } else {
                dock_preferences.HideMode = Plank.HideType.NONE;
            }
        });

        monitor = new Gtk.ComboBoxText ();

        primary_monitor_label = new Gtk.Label (_("Primary display:"));
        primary_monitor_label.halign = Gtk.Align.END;
        primary_monitor_label.no_show_all = true;

        monitor_label = new Gtk.Label (_("Display:"));
        monitor_label.no_show_all = true;
        monitor_label.halign = Gtk.Align.END;

        primary_monitor = new Gtk.Switch ();
        primary_monitor.no_show_all = true;
        primary_monitor.notify["active"].connect (() => {
            if (primary_monitor.active == true) {
                dock_preferences.Monitor = "";
                monitor_label.sensitive = false;
                monitor.sensitive = false;
            } else {
                var plug_names = get_monitor_plug_names (get_display ());
                if (plug_names.length > monitor.active)
                    dock_preferences.Monitor = plug_names[monitor.active];
                monitor_label.sensitive = true;
                monitor.sensitive = true;
            }
        });
        primary_monitor.active = (dock_preferences.Monitor == "");

        monitor.notify["active"].connect (() => {
            if (monitor.active >= 0 && primary_monitor.active == false) {
                var plug_names = get_monitor_plug_names (get_display ());
                if (plug_names.length > monitor.active)
                    dock_preferences.Monitor = plug_names[monitor.active];
            }
        });

        get_screen ().monitors_changed.connect (() => {check_for_screens ();});

        var icon_label = new Gtk.Label (_("Icon size:"));
        icon_label.halign = Gtk.Align.END;
        var hide_label = new Gtk.Label (_("Hide when:"));
        hide_label.halign = Gtk.Align.END;
        var primary_monitor_grid = new Gtk.Grid ();
        primary_monitor_grid.add (primary_monitor);
        var pressure_label = new Gtk.Label (_("Pressure reveal:"));
        pressure_label.halign = Gtk.Align.END;

        attach (icon_label, 1, 0, 1, 1);
        attach (icon_size_grid, 2, 0, 2);
        attach (hide_label, 1, 1, 1, 1);
        attach (hide_mode, 2, 1, 1, 1);
        attach (hide_switch, 3, 1, 1, 1);
        attach (primary_monitor_label, 1, 3, 1, 1);
        attach (primary_monitor_grid, 2, 3, 1, 1);
        attach (monitor_label, 1, 4, 1, 1);
        attach (monitor, 2, 4, 1, 1);
        attach (pressure_label, 1, 5, 1, 1);
        attach (pressure_switch, 2, 5, 1, 1);

        check_for_screens ();

        switch (dock_preferences.IconSize) {
            case 32:
                icon_size_32.active = true;
                break;
            case 48:
                icon_size_48.active = true;
                break;
            case 64:
                icon_size_64.active = true;
                break;
            default:
                icon_size_unsupported.active = true;
                debug ("Unsupported dock icon size");
        }

        icon_size_32.toggled.connect (() => {
            dock_preferences.IconSize = 32;
        });

        icon_size_48.toggled.connect (() => {
            dock_preferences.IconSize = 48;
        });

        icon_size_64.toggled.connect (() => {
            dock_preferences.IconSize = 64;
        });
    }

    private void check_for_screens () {
        int i = 0;
        int primary_screen = 0;
        var default_display = get_display ();
        var default_screen = get_screen ();
        monitor.remove_all ();
        try {
            var screen = new Gnome.RRScreen (default_screen);
            for (i = 0; i < default_display.get_n_monitors () ; i++) {
                var monitor_plug_name = default_display.get_monitor (i).model;

                if (monitor_plug_name != null) {
                    unowned Gnome.RROutput output = screen.get_output_by_name (monitor_plug_name);
                    if (output != null && output.get_display_name () != null && output.get_display_name () != "") {
                        monitor.append_text (output.get_display_name ());
                        if (output.get_is_primary () == true) {
                            primary_screen = i;
                        }
                        continue;
                    }
                }

                monitor.append_text (_("Monitor %d").printf (i + 1) );
            }
        } catch (Error e) {
            critical (e.message);
            for (i = 0; i < default_display.get_n_monitors () ; i ++) {
                monitor.append_text (_("Display %d").printf (i + 1));
            }
        }

        if (i <= 1) {
            primary_monitor_label.hide ();
            primary_monitor.hide ();
            monitor_label.hide ();
            monitor.no_show_all = true;
            monitor.hide ();
        } else {
            if (dock_preferences.Monitor != "") {
                monitor.active = find_monitor_number (get_display (), dock_preferences.Monitor);
            } else {
                monitor.active = primary_screen;
            }

            primary_monitor_label.show ();
            primary_monitor.show ();
            monitor_label.show ();
            monitor.show ();
        }
    }

    static string[] get_monitor_plug_names (Gdk.Display display) {
        int n_monitors = display.get_n_monitors ();
        var result = new string[n_monitors];

        for (int i = 0; i < n_monitors; i++) {
            result[i] = display.get_monitor (i).model;
        }

        return result;
    }

    static int find_monitor_number (Gdk.Display display, string plug_name) {
        int n_monitors = display.get_n_monitors ();

        for (int i = 0; i < n_monitors; i++) {
            var monitor = display.get_monitor (i);
            var name = monitor.get_model ();
            if (plug_name == name)
                return i;
        }

        return display.get_n_monitors ();
    }

}
