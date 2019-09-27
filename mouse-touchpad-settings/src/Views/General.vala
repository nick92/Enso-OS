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

public class MouseTouchpad.GeneralView : Gtk.Grid {
    public Backend.MouseSettings mouse_settings { get; construct; }

    private Granite.Widgets.ModeButton primary_button_switcher;

    public GeneralView (Backend.MouseSettings mouse_settings) {
        Object (mouse_settings: mouse_settings);
    }

    construct {
        var primary_button_label = new SettingLabel (_("Primary button:"));
        primary_button_label.margin_bottom = 18;

        var mouse_left = new Gtk.Image.from_icon_name ("mouse-left-symbolic", Gtk.IconSize.DND);
        mouse_left.tooltip_text = _("Left");

        var mouse_right = new Gtk.Image.from_icon_name ("mouse-right-symbolic", Gtk.IconSize.DND);
        mouse_right.tooltip_text = _("Right");

        primary_button_switcher = new Granite.Widgets.ModeButton ();
        primary_button_switcher.halign = Gtk.Align.START;
        primary_button_switcher.margin_bottom = 18;
        primary_button_switcher.width_request = 256;

        if (Gtk.StateFlags.DIR_LTR in get_state_flags ()) {
            primary_button_switcher.append (mouse_left);
            primary_button_switcher.append (mouse_right);

            mouse_settings.bind_property (
                "left-handed",
                primary_button_switcher,
                "selected",
                BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
            );
        } else {
            primary_button_switcher.append (mouse_right);
            primary_button_switcher.append (mouse_left);

            update_rtl_modebutton ();

            mouse_settings.notify["left-handed"].connect (() => {
                update_rtl_modebutton ();
            });

            primary_button_switcher.mode_changed.connect (() => {
                if (primary_button_switcher.selected == 0) {
                    mouse_settings.left_handed = true;
                } else {
                    mouse_settings.left_handed = false;
                }
            });
        }

        var locate_pointer_help = new Gtk.Label (_("Pressing the control key will highlight the position of the pointer"));
        locate_pointer_help.margin_bottom = 18;
        locate_pointer_help.wrap = true;
        locate_pointer_help.xalign = 0;
        locate_pointer_help.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var hold_label = new SettingLabel (_("Long-press secondary click:"));

        var hold_switch = new Gtk.Switch ();
        hold_switch.halign = Gtk.Align.START;

        var hold_help = new Gtk.Label (_("Long-pressing and releasing the primary button will secondary click."));
        hold_help.margin_bottom = 18;
        hold_help.wrap = true;
        hold_help.xalign = 0;
        hold_help.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var hold_length_label = new SettingLabel (_("Length:"));

        var hold_scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0.5, 2.0, 0.1);
        hold_scale.draw_value = false;
        hold_scale.hexpand = true;
        hold_scale.width_request = 160;
        hold_scale.add_mark (1.2, Gtk.PositionType.TOP, null);

        var reveal_pointer_switch = new Gtk.Switch ();
        reveal_pointer_switch.halign = Gtk.Align.START;

        var keypad_pointer_switch = new Gtk.Switch ();
        keypad_pointer_switch.halign = Gtk.Align.START;

        var keypad_pointer_adjustment = new Gtk.Adjustment (0, 0, 500, 10, 10, 10);

        var pointer_speed_label = new SettingLabel (_("Speed:"));

        var pointer_speed_scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, keypad_pointer_adjustment);
        pointer_speed_scale.draw_value = false;
        pointer_speed_scale.add_mark (10, Gtk.PositionType.TOP, null);

        var pointer_speed_help = new Gtk.Label (_("This disables both levels of keys on the numeric keypad."));
        pointer_speed_help.margin_bottom = 18;

        pointer_speed_help.wrap = true;
        pointer_speed_help.xalign = 0;
        pointer_speed_help.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        row_spacing = 6;
        column_spacing = 12;

        attach (primary_button_label, 0, 0);
        attach (primary_button_switcher, 1, 0, 3);

        attach (hold_label, 0, 1);
        attach (hold_switch, 1, 1);
        attach (hold_length_label, 2, 1);
        attach (hold_scale, 3, 1);
        attach (hold_help, 1, 2, 3);

        attach (new SettingLabel (_("Reveal pointer:")), 0, 6);
        attach (reveal_pointer_switch, 1, 6, 3);
        attach (locate_pointer_help, 1, 7, 3);

        attach (new SettingLabel (_("Control pointer using keypad:")), 0, 8);
        attach (keypad_pointer_switch, 1, 8);
        attach (pointer_speed_label, 2, 8);
        attach (pointer_speed_scale, 3, 8);
        attach (pointer_speed_help, 1, 9, 3);

        var xsettings_schema = SettingsSchemaSource.get_default ().lookup ("org.gnome.settings-daemon.plugins.xsettings", false);
        if (xsettings_schema != null) {
            var primary_paste_switch = new Gtk.Switch ();
            primary_paste_switch.halign = Gtk.Align.START;

            var primary_paste_help = new Gtk.Label (_("Middle or three-finger clicking on an input will paste any selected text"));
            primary_paste_help.margin_bottom = 18;
            primary_paste_help.wrap = true;
            primary_paste_help.xalign = 0;
            primary_paste_help.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            attach (new SettingLabel (_("Middle click paste:")), 0, 4);
            attach (primary_paste_switch, 1, 4);
            attach (primary_paste_help, 1, 5, 3);

            var xsettings = new GLib.Settings ("org.gnome.settings-daemon.plugins.xsettings");
            primary_paste_switch.notify["active"].connect (() => on_primary_paste_switch_changed (primary_paste_switch, xsettings));

            var current_value = xsettings.get_value ("overrides").lookup_value ("Gtk/EnablePrimaryPaste", VariantType.INT32);
            if (current_value != null) {
                primary_paste_switch.active = current_value.get_int32 () == 1;
            }
        }

        var daemon_settings = new GLib.Settings ("org.gnome.settings-daemon.peripherals.mouse");
        daemon_settings.bind ("locate-pointer", reveal_pointer_switch, "active", GLib.SettingsBindFlags.DEFAULT);

        var a11y_mouse_settings = new GLib.Settings ("org.gnome.desktop.a11y.mouse");
        a11y_mouse_settings.bind ("secondary-click-enabled", hold_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        a11y_mouse_settings.bind ("secondary-click-time", hold_scale.adjustment, "value", GLib.SettingsBindFlags.DEFAULT);

        hold_switch.bind_property ("active", hold_length_label, "sensitive", BindingFlags.SYNC_CREATE);
        hold_switch.bind_property ("active", hold_scale, "sensitive", BindingFlags.SYNC_CREATE);

        var a11y_keyboard_settings = new GLib.Settings ("org.gnome.desktop.a11y.keyboard");
        a11y_keyboard_settings.bind ("mousekeys-enable", keypad_pointer_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        a11y_keyboard_settings.bind ("mousekeys-max-speed", keypad_pointer_adjustment, "value", SettingsBindFlags.DEFAULT);
        a11y_keyboard_settings.bind ("mousekeys-enable", pointer_speed_scale, "sensitive", SettingsBindFlags.GET);
        a11y_keyboard_settings.bind ("mousekeys-enable", pointer_speed_label, "sensitive", SettingsBindFlags.GET);
    }

    private void update_rtl_modebutton () {
        if (mouse_settings.left_handed) {
            primary_button_switcher.selected = 0;
        } else {
            primary_button_switcher.selected = 1;
        }
    }

    private void on_primary_paste_switch_changed (Gtk.Switch switch, GLib.Settings xsettings) {
        var overrides = xsettings.get_value ("overrides");
        var dict = new VariantDict (overrides);
        dict.insert_value ("Gtk/EnablePrimaryPaste", new Variant.int32 (switch.active ? 1 : 0));

        overrides = dict.end ();
        xsettings.set_value ("overrides", overrides);
    }
}

