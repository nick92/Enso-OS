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

public class Launchy : Gtk.Grid {
    Gtk.Label primary_monitor_label;
    Gtk.Switch primary_monitor;
    Gtk.Label monitor_label;
    Gtk.ComboBoxText monitor;
    GLib.Settings settings;

    public Launchy () {
        column_spacing = 12;
        halign = Gtk.Align.CENTER;
        row_spacing = 6;
        margin_start = margin_end = 6;

        settings = new GLib.Settings ("org.enso.launchy");

        var category_switch = new Gtk.Switch ();
        var top_switch = new Gtk.Switch ();
        var icon_size = new Granite.Widgets.ModeButton ();
        icon_size.append_text (_("Small"));
        icon_size.append_text (_("Normal"));
        icon_size.append_text (_("Large"));
        var current = settings.get_int("icon-size");

        switch (current) {
            case 44:
                icon_size.selected = 0;
                break;
            case 50:
                icon_size.selected = 1;
                break;
            case 60:
                icon_size.selected = 2;
                break;
            default:
                icon_size.append_text (_("Custom (%dpx)").printf (current));
                icon_size.selected = 3;
                break;
        }

        icon_size.mode_changed.connect (() => {
            switch (icon_size.selected) {
                case 0:
                    settings.set_int("icon-size", 45);
                    break;
                case 1:
                    settings.set_int("icon-size", 50);
                    break;
                case 2:
                    settings.set_int("icon-size", 60);
                    break;
                case 3:
                    settings.set_int("icon-size", current);
                    break;
            }
        });

        category_switch.notify["active"].connect (() => {
    			if (category_switch.active) {
    				settings.set_boolean ("use-category", category_switch.active);
    			} else {
    				settings.set_boolean ("use-category", category_switch.active);
    			}
    		});

        top_switch.notify["active"].connect (() => {
    			if (top_switch.active) {
    				settings.set_boolean ("show-at-top", top_switch.active);
    			} else {
    				settings.set_boolean ("show-at-top", top_switch.active);
    			}
    		});

        top_switch.set_active (settings.get_boolean ("show-at-top"));
        top_switch.halign = Gtk.Align.START;
        top_switch.valign = Gtk.Align.CENTER;

        category_switch.set_active (settings.get_boolean ("use-category"));
        category_switch.halign = Gtk.Align.START;
        category_switch.valign = Gtk.Align.CENTER;

        var icon_label = new Gtk.Label (_("Icon size:"));
        icon_label.halign = Gtk.Align.END;
        var category_label = new Gtk.Label (_("Start on Category view:"));
        category_label.halign = Gtk.Align.END;
        var top_label = new Gtk.Label (_("Display at top:"));
        top_label.halign = Gtk.Align.END;

        attach (icon_label, 1, 0, 1, 1);
        attach (icon_size, 2, 0, 1, 1);
        attach (category_label, 1, 1, 1, 1);
        attach (category_switch, 2, 1, 1, 1);
        attach (top_label, 1, 2, 1, 1);
        attach (top_switch, 2, 2, 1, 1);
    }
}
