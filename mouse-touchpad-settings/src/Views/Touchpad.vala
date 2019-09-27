/*
 * Copyright (c) 2011-2018 elementary, Inc. (https://elementary.io)
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

public class MouseTouchpad.TouchpadView : Gtk.Grid {
    public Backend.TouchpadSettings touchpad_settings { get; construct; }

    public TouchpadView (Backend.TouchpadSettings touchpad_settings) {
        Object (touchpad_settings: touchpad_settings);
    }

    construct {
        var glib_settings = new GLib.Settings ("org.gnome.desktop.peripherals.touchpad");

        var disable_while_typing_switch = new Gtk.Switch ();
        disable_while_typing_switch.halign = Gtk.Align.START;

        var tap_to_click_switch = new Gtk.Switch ();
        tap_to_click_switch.halign = Gtk.Align.START;

        var click_method_switch = new Gtk.Switch ();
        click_method_switch.halign = Gtk.Align.START;
        click_method_switch.valign = Gtk.Align.CENTER;

        if (glib_settings.get_enum ("click-method").to_string () == "none") {
            click_method_switch.active = false;
        } else {
            click_method_switch.active = true;
        }

        var click_method_combobox = new Gtk.ComboBoxText ();
        click_method_combobox.hexpand = true;
        click_method_combobox.append ("default", _("Hardware default"));
        click_method_combobox.append ("fingers", _("Multitouch"));
        click_method_combobox.append ("areas", _("Touchpad areas"));

        if (click_method_combobox.active_id == null ) {
            click_method_combobox.active_id = "default";
        }

        var pointer_speed_adjustment = new Gtk.Adjustment (0, -1, 1, 0.1, 0, 0);

        var pointer_speed_scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, pointer_speed_adjustment);
        pointer_speed_scale.digits = 2;
        pointer_speed_scale.draw_value = false;
        pointer_speed_scale.add_mark (0, Gtk.PositionType.BOTTOM, null);

        var scrolling_combobox = new Gtk.ComboBoxText ();
        scrolling_combobox.append ("two-finger-scrolling", _("Two-finger"));
        scrolling_combobox.append ("edge-scrolling", _("Edge"));
        scrolling_combobox.append ("disabled", _("Disabled"));

        var horizontal_scrolling_switch = new Gtk.Switch ();
        horizontal_scrolling_switch.halign = Gtk.Align.START;

        var natural_scrolling_switch = new Gtk.Switch ();
        natural_scrolling_switch.halign = Gtk.Align.START;

        var disable_with_mouse_switch = new Gtk.Switch ();
        disable_with_mouse_switch.halign = Gtk.Align.START;

        if (glib_settings.get_string ("send-events") == "disabled-on-external-mouse") {
            disable_with_mouse_switch.active = true;
        } else {
            disable_with_mouse_switch.active = false;
        }

        row_spacing = 12;
        column_spacing = 12;

        attach (new SettingLabel (_("Pointer speed:")), 0, 0);
        attach (pointer_speed_scale, 1, 0, 2, 1);
        attach (new SettingLabel (_("Tap to click:")), 0, 1);
        attach (tap_to_click_switch, 1, 1);
        attach (new SettingLabel (_("Physical clicking:")), 0, 2);
        attach (click_method_switch, 1, 2);
        attach (click_method_combobox, 2, 2);
        attach (new SettingLabel (_("Scrolling:")), 0, 3);
        attach (scrolling_combobox, 1, 3, 2, 1);
        attach (new SettingLabel (_("Natural scrolling:")), 0, 4);
        attach (natural_scrolling_switch, 1, 4);
        attach (new SettingLabel (_("Ignore while typing:")), 0, 5);
        attach (disable_while_typing_switch, 1, 5);
        attach (new SettingLabel (_("Ignore when mouse is connected:")), 0, 6);
        attach (disable_with_mouse_switch, 1, 6);

        click_method_switch.bind_property ("active", click_method_combobox, "sensitive", BindingFlags.SYNC_CREATE);

        click_method_switch.notify["active"].connect (() => {
            if (click_method_switch.active) {
                touchpad_settings.click_method = click_method_combobox.active_id;
            } else {
                touchpad_settings.click_method = "none";
            }
        });

        if (!glib_settings.get_boolean ("edge-scrolling-enabled") && !glib_settings.get_boolean ("two-finger-scrolling-enabled")) {
            scrolling_combobox.active_id = "disabled";
        } else if (glib_settings.get_boolean ("two-finger-scrolling-enabled")) {
            scrolling_combobox.active_id = "two-finger-scrolling";
        } else {
            scrolling_combobox.active_id = "edge-scrolling";
        }

        scrolling_combobox.changed.connect (() => {
            string active_text = scrolling_combobox.get_active_id ();

            switch (active_text) {
                case "disabled":
                    glib_settings.set_boolean ("edge-scrolling-enabled", false);
                    glib_settings.set_boolean ("two-finger-scrolling-enabled", false);
                    break;
                case "two-finger-scrolling":
                    glib_settings.set_boolean ("edge-scrolling-enabled", false);
                    glib_settings.set_boolean ("two-finger-scrolling-enabled", true);
                    break;
                case "edge-scrolling":
                    glib_settings.set_boolean ("edge-scrolling-enabled", true);
                    glib_settings.set_boolean ("two-finger-scrolling-enabled", false);
                    break;
            }

            horizontal_scrolling_switch.sensitive = active_text != "disabled";
            natural_scrolling_switch.sensitive = active_text != "disabled";
        });

        touchpad_settings.bind_property (
            "click-method",
            click_method_combobox,
            "active-id",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE,
            click_method_transform_func
        );

        disable_with_mouse_switch.notify["active"].connect (() => {
            if (disable_with_mouse_switch.active) {
                glib_settings.set_string ("send-events", "disabled-on-external-mouse");
            } else {
                glib_settings.set_string ("send-events", "enabled");
            }
        });

        glib_settings.bind ("disable-while-typing", disable_while_typing_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        glib_settings.bind ("natural-scroll", natural_scrolling_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        glib_settings.bind ("speed", pointer_speed_adjustment, "value", GLib.SettingsBindFlags.DEFAULT);
        glib_settings.bind ("tap-to-click", tap_to_click_switch, "active", GLib.SettingsBindFlags.DEFAULT);
    }

    private bool click_method_transform_func (Binding binding, Value source_value, ref Value target_value) {
        if (touchpad_settings.click_method == "none") {
            return false;
        }

        target_value = source_value;
        return true;
    }
}

