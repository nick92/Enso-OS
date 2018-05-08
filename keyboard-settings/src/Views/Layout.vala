/*
* Copyright (c) 2017 elementary, LLC. (https://elementary.io)
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

namespace Pantheon.Keyboard.LayoutPage {
    // global handler
    LayoutHandler handler;

    public class Page : Pantheon.Keyboard.AbstractPage {
        private LayoutPage.Display display;
        private LayoutSettings settings;
        private Gtk.SizeGroup [] size_group;
        private AdvancedSettings advanced_settings;

        public override void reset () {
            settings.reset_all ();
            display.reset_all ();
            return;
        }

        public Page () {
            this.column_homogeneous = true;

            handler  = new LayoutHandler ();
            settings = LayoutSettings.get_instance ();
            size_group = {new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL),
                          new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL)};

            // tree view to display the current layouts
            display = new LayoutPage.Display ();

            var switch_layout_label = new SettingsLabel (_("Switch layout:"), size_group[0]);

            // Layout switching keybinding
            var modifier = new Xkb_modifier ("switch-layout");
            modifier.append_xkb_option ("", _("Disabled"));
            modifier.append_xkb_option ("grp:alt_caps_toggle", _("Alt + Caps Lock"));
            modifier.append_xkb_option ("grp:alt_shift_toggle", _("Alt + Shift"));
            modifier.append_xkb_option ("grp:alt_space_toggle", _("Alt + Space"));
            modifier.append_xkb_option ("grp:shifts_toggle", _("Both Shift keys together"));
            modifier.append_xkb_option ("grp:caps_toggle", _("Caps Lock"));
            modifier.append_xkb_option ("grp:ctrl_alt_toggle", _("Ctrl + Alt"));
            modifier.append_xkb_option ("grp:ctrl_shift_toggle", _("Ctrl + Shift"));
            modifier.append_xkb_option ("grp:shift_caps_toggle", _("Shift + Caps Lock"));
            modifier.set_default_command ("");

            settings.add_xkb_modifier (modifier);

            var switch_layout_combo = new XkbComboBox (modifier, size_group[1]);

            var compose_key_label = new SettingsLabel (_("Compose key:"), size_group[0]);

            // Compose key position menu
            modifier = new Xkb_modifier ();
            modifier.append_xkb_option ("", _("Disabled"));
            modifier.append_xkb_option ("compose:caps", _("Caps Lock"));
            modifier.append_xkb_option ("compose:menu", _("Menu"));
            modifier.append_xkb_option ("compose:ralt", _("Right Alt"));
            modifier.append_xkb_option ("compose:rctrl", _("Right Ctrl"));
            modifier.append_xkb_option ("compose:rwin", _("Right ⌘"));
            modifier.set_default_command ("");

            settings.add_xkb_modifier (modifier);

            var compose_key_combo = new XkbComboBox (modifier, size_group[1]);

            var overlay_key_label = new SettingsLabel (_("⌘ key behavior:"), size_group[0]);

            var overlay_key_combo = new Gtk.ComboBoxText ();
            overlay_key_combo.halign = Gtk.Align.START;
            overlay_key_combo.append_text (_("Disabled"));
            overlay_key_combo.append_text (_("Applications Menu"));

            string? cheatsheet_path = Environment.find_program_in_path ("io.elementary.shortcut-overlay");
            if (cheatsheet_path != null) {
                overlay_key_combo.append_text (_("Shortcut Overlay"));
            }

            size_group[1].add_widget (overlay_key_combo);

            var caps_lock_label = new SettingsLabel (_("Caps Lock behavior:"), size_group[0]);

            // Caps Lock key functionality
            modifier = new Xkb_modifier ();
            modifier.append_xkb_option ("", _("Default"));
            modifier.append_xkb_option ("caps:none", _("Caps Lock disabled"));
            modifier.append_xkb_option ("caps:backspace", _("as Backspace"));
            modifier.append_xkb_option ("ctrl:nocaps", _("as Ctrl"));
            modifier.append_xkb_option ("caps:escape", _("as Escape"));
            modifier.append_xkb_option ("caps:numlock", _("as Num Lock"));
            modifier.append_xkb_option ("caps:super", _("as ⌘"));
            modifier.append_xkb_option ("ctrl:swapcaps", _("Swap with Control"));
            modifier.append_xkb_option ("caps:swapescape", _("Swap with Escape"));

            modifier.set_default_command ("");
            settings.add_xkb_modifier (modifier);

            var caps_lock_combo = new XkbComboBox (modifier, size_group[1]);

            // Advanced settings panel
            AdvancedSettingsPanel? [] panels = {fifth_level_layouts_panel (),
                                                japanese_layouts_panel (),
                                                korean_layouts_panel (),
                                                third_level_layouts_panel ()};

            advanced_settings = new AdvancedSettings (panels);
            advanced_settings.hexpand = advanced_settings.vexpand = true;
            advanced_settings.valign = Gtk.Align.START;

            var entry_test = new Gtk.Entry ();
            entry_test.hexpand = entry_test.vexpand = true;
            entry_test.placeholder_text = (_("Type to test your layout"));
            entry_test.valign = Gtk.Align.END;

            attach (display, 0, 0, 1, 6);
            attach (switch_layout_label, 1, 0, 1, 1);
            attach (switch_layout_combo, 2, 0, 1, 1);
            attach (compose_key_label, 1, 1, 1, 1);
            attach (compose_key_combo, 2, 1, 1, 1);
            attach (overlay_key_label, 1, 2, 1, 1);
            attach (overlay_key_combo, 2, 2, 1, 1);
            attach (caps_lock_label, 1, 3, 1, 1);
            attach (caps_lock_combo, 2, 3, 1, 1);
            attach (advanced_settings, 1, 4, 2, 1);
            attach (entry_test, 1, 5, 2, 1);

            // Cannot be just called from the constructor because the stack switcher
            // shows every child after the constructor has been called
            advanced_settings.map.connect (() => {
                show_panel_for_active_layout ();
            });

            settings.layouts.active_changed.connect (() => {
                show_panel_for_active_layout ();
            });

            var gala_behavior_settings = new GLib.Settings ("org.pantheon.desktop.gala.behavior");

            var overlay_string = gala_behavior_settings.get_string ("overlay-action");

            switch (overlay_string) {
                case "":
                    overlay_key_combo.active = 0;
                    break;
                case "launchy":
                    overlay_key_combo.active = 1;
                    break;
                case "io.elementary.shortcut-overlay":
                    overlay_key_combo.active = 2;
                    break;
            }

            overlay_key_combo.changed.connect (() => {
                var combo_active = overlay_key_combo.active;

                if (combo_active == 0) {
                    gala_behavior_settings.set_string ("overlay-action", "");
                } else if (combo_active == 1) {
                    gala_behavior_settings.set_string ("overlay-action", "launchy");
                } else if (combo_active == 2) {
                    gala_behavior_settings.set_string ("overlay-action", "io.elementary.shortcut-overlay");
                }
            });
        }

        private AdvancedSettingsPanel? third_level_layouts_panel () {
            var modifier = settings.get_xkb_modifier_by_name ("third_level_key");

            if (modifier == null) {
                return null;
            }

            string [] invalid_input_sources = {"am*", "ara*", "az+cyrillic",
                                               "bg*", "by", "by+legacy",
                                               "ca+eng", "ca+ike", "cm", "cn*", "cz+ucw",
                                               "fr+dvorak",
                                               "ge+os", "ge+ru", "gr+nodeadkeys", "gr+simple",
                                               "ie+ogam", "il*", "in+ben_gitanjali", "in+ben_inscript", "in+tam_keyboard_with_numerals",
                                               "in+tam_TAB", "in+tam_TSCII", "in+tam_unicode", "iq",
                                               "jp*",
                                               "kg*", "kz*",
                                               "la*", "lk+tam_TAB", "lk+tam_unicode",
                                               "mk*", "mv*",
                                               "no+mac", "no+mac_nodeadkeys", "np*",
                                               "pk+ara",
                                               "ru", "ru+dos", "ru+legacy", "ru+mac", "ru+os_legacy", "ru+os_winkeys",
                                               "ru+phonetic", "ru+phonetic_winkeys", "ru+typewriter", "ru+typewriter-legacy",
                                               "sy", "sy+syc", "sy+syc_phonetic",
                                               "th*", "tz*",
                                               "ua+homophonic", "ua+legacy", "ua+phonetic", "ua+rstu", "ua+rstu_ru",
                                               "ua+typewriter", "ua+winkeys", "us", "us+chr", "us+dvorak", "us+dvorak-classic",
                                               "us+dvorak-l", "us+dvorak-r", "uz*"};

            var third_level_label = new SettingsLabel (_("Key to choose 3rd level:"), size_group[0]);

            var panel = new AdvancedSettingsPanel ("third_level_layouts", {}, invalid_input_sources);

            var third_level_combo = new XkbComboBox (modifier, size_group[1]);

            panel.attach (third_level_label, 0, 0, 1, 1);
            panel.attach (third_level_combo, 1, 0, 1, 1);

            panel.show_all ();

            return panel;
        }

        private AdvancedSettingsPanel fifth_level_layouts_panel () {
            var panel = new AdvancedSettingsPanel ("fifth_level_layouts", {"ca+multix"});

            var third_level_label = new SettingsLabel (_("Key to choose 3rd level:"), size_group[0]);

            Xkb_modifier modifier = new Xkb_modifier ("third_level_key");
            modifier.append_xkb_option ("", _("Default"));
            modifier.append_xkb_option ("lv3:caps_switch", _("Caps Lock"));
            modifier.append_xkb_option ("lv3:lalt_switch", _("Left Alt"));
            modifier.append_xkb_option ("lv3:ralt_switch", _("Right Alt"));
            modifier.append_xkb_option ("lv3:switch", _("Right Ctrl"));
            modifier.append_xkb_option ("lv3:rwin", _("Right ⌘"));

            modifier.set_default_command ("");
            settings.add_xkb_modifier (modifier);

            var third_level_combo = new XkbComboBox (modifier, size_group[1]);

            var fifth_level_label = new SettingsLabel (_("Key to choose 5th level:"), size_group[0]);

            modifier = new Xkb_modifier ();
            modifier.append_xkb_option ("lv5:ralt_switch_lock", _("Right Alt"));
            modifier.append_xkb_option ("", _("Right Ctrl"));
            modifier.append_xkb_option ("lv5:rwin_switch_lock", _("Right ⌘"));
            modifier.set_default_command ("");
            settings.add_xkb_modifier (modifier);

            var fifth_level_combo = new XkbComboBox (modifier, size_group[1]);

            panel.attach (third_level_label, 0, 0, 1, 1);
            panel.attach (third_level_combo, 1, 0, 1, 1);
            panel.attach (fifth_level_label, 0, 1, 1, 1);
            panel.attach (fifth_level_combo, 1, 1, 1, 1);
            panel.show_all ();

            return panel;
        }

        private AdvancedSettingsPanel japanese_layouts_panel () {
            var kana_lock_label = new SettingsLabel (_("Kana Lock:"), size_group[0]);
            var kana_lock_switch = new XkbOptionSwitch (settings, "japan:kana_lock");

            // Used to align this grid without expanding the switch itself
            var spacer_grid = new Gtk.Grid ();
            spacer_grid.add (kana_lock_switch);
            size_group[1].add_widget (spacer_grid);

            var nicola_backspace_label = new SettingsLabel (_("Nicola F Backspace:"), size_group[0]);
            var nicola_backspace_switch = new XkbOptionSwitch (settings, "japan:nicola_f_bs");

            var zenkaku_label = new SettingsLabel (_("Zenkaku Hankaku as Escape:"), size_group[0]);
            var zenkaku_switch = new XkbOptionSwitch (settings, "japan:hztg_escape");

            string [] valid_input_sources = {"jp"};
            var panel = new AdvancedSettingsPanel ( "japanese_layouts", valid_input_sources );
            panel.attach (kana_lock_label, 0, 0, 1, 1);
            panel.attach (spacer_grid, 1, 0, 1, 1);
            panel.attach (nicola_backspace_label, 0, 1, 1, 1);
            panel.attach (nicola_backspace_switch, 1, 1, 1, 1);
            panel.attach (zenkaku_label, 0, 2, 1, 1);
            panel.attach (zenkaku_switch, 1, 2, 1, 1);
            panel.show_all ();

            return panel;
        }

        private AdvancedSettingsPanel korean_layouts_panel () {
            var hangul_label = new SettingsLabel (_("Hangul/Hanja keys on Right Alt/Ctrl:"), size_group[0]);
            var hangul_switch = new XkbOptionSwitch (settings, "korean:ralt_rctrl");

            // Used to align this grid without expanding the switch itself
            var spacer_grid = new Gtk.Grid ();
            spacer_grid.add (hangul_switch);
            size_group[1].add_widget (spacer_grid);

            string [] valid_input_sources = {"kr"};
            var panel = new AdvancedSettingsPanel ("korean_layouts", valid_input_sources);
            panel.attach (hangul_label, 0, 0, 1, 1);
            panel.attach (spacer_grid, 1, 0, 1, 1);
            panel.show_all ();

            return panel;
        }

        private void show_panel_for_active_layout () {
            Layout active_layout = settings.layouts.get_layout (settings.layouts.active);
            advanced_settings.set_visible_panel_from_layout (active_layout.name);
        }

        private class XkbComboBox : Gtk.ComboBoxText {
            public XkbComboBox (Xkb_modifier modifier, Gtk.SizeGroup size_group) {
                halign = Gtk.Align.START;
                valign = Gtk.Align.CENTER;
                size_group.add_widget (this);

                for (int i = 0; i < modifier.xkb_option_commands.length; i++) {
                    append (modifier.xkb_option_commands[i], modifier.option_descriptions[i]);
                }

                set_active_id (modifier.get_active_command ());

                changed.connect (() => {
                    modifier.update_active_command (active_id);
                });

                modifier.active_command_updated.connect (() => {
                    set_active_id (modifier.get_active_command ());
                });
            }
        }

        private class XkbOptionSwitch : Gtk.Switch {
            public XkbOptionSwitch (LayoutSettings settings, string xkb_command) {
                halign = Gtk.Align.START;
                valign = Gtk.Align.CENTER;

                var modifier = new Xkb_modifier ("" + xkb_command);
                modifier.append_xkb_option ("", "option off");
                modifier.append_xkb_option (xkb_command, "option on");

                settings.add_xkb_modifier (modifier);

                if (modifier.get_active_command () == "") {
                    active = false;
                } else {
                    active = true;
                }

                notify["active"].connect(() => {
                    if (active) {
                        modifier.update_active_command (xkb_command);
                    } else {
                        modifier.update_active_command ("");
                    }
                });
            }
        }

        private class SettingsLabel : Gtk.Label {
            public SettingsLabel (string label, Gtk.SizeGroup size_group) {
                Object (label: label);
                xalign = 1;
                size_group.add_widget (this);
            }
        }
    }
}
