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
			handler  = new LayoutHandler ();
			settings = LayoutSettings.get_instance ();
            size_group = { new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL),
                           new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL) };

            // Layout switching keybinding
            new_label (this, _("Switch layout:"), 0, 1);
            Xkb_modifier modifier = new Xkb_modifier ("switch-layout");

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

            new_combo_box (this, modifier, 0, 2);

            // Compose key position menu
            new_label (this, _("Compose key:"), 1, 1);
            modifier = new Xkb_modifier ();
            modifier.append_xkb_option ("", _("Disabled"));
            modifier.append_xkb_option ("compose:caps", _("Caps Lock"));
            modifier.append_xkb_option ("compose:ralt", _("Right Alt"));
            modifier.append_xkb_option ("compose:rctrl", _("Right Ctrl"));
            modifier.append_xkb_option ("compose:rwin", _("Right Super"));

            modifier.set_default_command ("");
            settings.add_xkb_modifier (modifier);

            new_combo_box (this, modifier, 1, 2);

            // Caps Lock key functionality
            new_label (this, _("Caps Lock behavior:"), 2, 1);

            modifier = new Xkb_modifier ();
            modifier.append_xkb_option ("", _("Default"));
            modifier.append_xkb_option ("caps:none", _("Caps Lock disabled"));
            modifier.append_xkb_option ("caps:backspace", _("as Backspace"));
            modifier.append_xkb_option ("ctrl:nocaps", _("as Ctrl"));
            modifier.append_xkb_option ("caps:escape", _("as Escape"));
            modifier.append_xkb_option ("caps:numlock", _("as Num Lock"));
            modifier.append_xkb_option ("caps:super", _("as Super"));
            modifier.append_xkb_option ("ctrl:swapcaps", _("Swap with Control"));
            modifier.append_xkb_option ("caps:swapescape", _("Swap with Escape"));

            modifier.set_default_command ("");
            settings.add_xkb_modifier (modifier);

            new_combo_box (this, modifier, 2, 2);

			// tree view to display the current layouts
			display = new LayoutPage.Display ();
            this.attach (display, 0, 0, 1, 5);

            // Advanced settings panel
            AdvancedSettingsPanel [] panels = { fifth_level_layouts_panel (),
                                                japanese_layouts_panel (),
                                                korean_layouts_panel (),
                                                third_level_layouts_panel ()};

            this.advanced_settings = new AdvancedSettings (panels);

            advanced_settings.hexpand = advanced_settings.vexpand = true;
            advanced_settings.valign = Gtk.Align.START;
            this.attach (advanced_settings, 1, 3, 2, 1);

            // Cannot be just called from the constructor because the stack switcher
            // shows every child after the constructor has been called
            advanced_settings.map.connect (() => {
                show_panel_for_active_layout ();
            });

            settings.layouts.active_changed.connect (() => {
                show_panel_for_active_layout ();
            });

			// Test entry
			var entry_test = new Gtk.Entry ();
			entry_test.placeholder_text = (_("Type to test your layout…"));

			entry_test.hexpand = entry_test.vexpand = true;
			entry_test.valign  = Gtk.Align.END;

            this.attach (entry_test, 1, 4, 2, 1);
		}

        private AdvancedSettingsPanel third_level_layouts_panel () {
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

            var panel = new AdvancedSettingsPanel ("third_level_layouts", {}, invalid_input_sources);

            new_label (panel, _("Key to choose 3rd level:"), 0);
            Xkb_modifier modifier = settings.get_xkb_modifier_by_name ("third_level_key");
            new_combo_box (panel, modifier, 0);

            panel.show_all ();

            return panel;
        }

        private AdvancedSettingsPanel fifth_level_layouts_panel () {
            var panel = new AdvancedSettingsPanel ("fifth_level_layouts", {"ca+multix"});

            new_label (panel, _("Key to choose 3rd level:"), 0);
            Xkb_modifier modifier = new Xkb_modifier ("third_level_key");
            modifier.append_xkb_option ("", _("Default"));
            modifier.append_xkb_option ("lv3:caps_switch", _("Caps Lock"));
            modifier.append_xkb_option ("lv3:lalt_switch", _("Left Alt"));
            modifier.append_xkb_option ("lv3:ralt_switch", _("Right Alt"));
            modifier.append_xkb_option ("lv3:switch", _("Right Ctrl"));
            modifier.append_xkb_option ("lv3:rwin", _("Right Super"));

            modifier.set_default_command ("");
            settings.add_xkb_modifier (modifier);
            new_combo_box (panel, modifier, 0);

            new_label (panel, _("Key to choose 5th level:"), 1);

            modifier = new Xkb_modifier ();
            modifier.append_xkb_option ("lv5:ralt_switch_lock", _("Right Alt"));
            modifier.append_xkb_option ("", _("Right Ctrl"));
            modifier.append_xkb_option ("lv5:rwin_switch_lock", _("Right Super"));
            modifier.set_default_command ( "" );
            settings.add_xkb_modifier (modifier);

            new_combo_box (panel, modifier, 1);

            panel.show_all ();

            return panel;
        }

        private AdvancedSettingsPanel japanese_layouts_panel () {
            string [] valid_input_sources = {"jp"};
            var panel = new AdvancedSettingsPanel ( "japanese_layouts", valid_input_sources );

            new_label (panel, _("Kana Lock:"), 0);
            new_xkb_option_switch (panel, "japan:kana_lock", 0);

            new_label (panel, _("Nicola F Backspace:"), 1);
            new_xkb_option_switch (panel, "japan:nicola_f_bs", 1);

            new_label (panel, _("Zenkaku Hankaku as Escape:"), 2);
            new_xkb_option_switch (panel, "japan:hztg_escape", 2);

            panel.show_all ();

            return panel;
        }

        private AdvancedSettingsPanel korean_layouts_panel () {
            string [] valid_input_sources = {"kr"};
            var panel = new AdvancedSettingsPanel ("korean_layouts", valid_input_sources);

            new_label (panel, _("Hangul/Hanja keys on Right Alt/Ctrl:"), 0);
            new_xkb_option_switch (panel, "korean:ralt_rctrl", 0);

            panel.show_all ();

            return panel;
        }

        // Function that adds a new switch to panel, and sets it up visually
        // and aligns it with external buttons
        private Gtk.Switch new_switch (Gtk.Grid panel, int v_position, int h_position = 1) {
            var new_switch = new Gtk.Switch ();
            new_switch.halign = Gtk.Align.START;
            new_switch.valign = Gtk.Align.CENTER;

            // There is a bug that makes the switch go outside its socket,
            // enclosing the switch in a box fixes that.
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.pack_start (new_switch, false, false, 0);
            panel.attach (box, h_position, v_position, 1, 1);
            size_group[1].add_widget (box);

            return new_switch;
        }

        // Function that adds a new switch but also configures its functionality
        // to enable/disable an xkb-option
        private Gtk.Switch new_xkb_option_switch
            (Gtk.Grid panel, string xkb_command, int v_position, int h_position = 1) {
            var new_switch = new_switch (panel, v_position, h_position);
            Xkb_modifier modifier = new Xkb_modifier (""+xkb_command);
            modifier.append_xkb_option ("", "option off");
            modifier.append_xkb_option (xkb_command, "option on");
            settings.add_xkb_modifier (modifier);

            if (modifier.get_active_command () == "") {
                new_switch.active = false;
            } else {
                new_switch.active = true;
            }

            new_switch.notify["active"].connect(() => {
                if (new_switch.active) {
                    modifier.update_active_command ( xkb_command );
                } else {
                    modifier.update_active_command ( "" );
                }
            });

            return new_switch;
        }

        private Gtk.ComboBoxText new_combo_box
            (Gtk.Grid panel, Xkb_modifier modifier, int v_position, int h_position = 1) {
            var new_combo_box = new Gtk.ComboBoxText ();

            for (int i = 0; i < modifier.xkb_option_commands.length; i++) {
                new_combo_box.append (modifier.xkb_option_commands[i], modifier.option_descriptions[i]);
            }

            new_combo_box.set_active_id (modifier.get_active_command () );

            new_combo_box.changed.connect (() => {
                modifier.update_active_command ( new_combo_box.active_id );
            });

            modifier.active_command_updated.connect (() => {
                new_combo_box.set_active_id (modifier.get_active_command () );
            });


            new_combo_box.halign = Gtk.Align.START;
            new_combo_box.valign = Gtk.Align.CENTER;
            panel.attach (new_combo_box, h_position, v_position, 1, 1);
            size_group[1].add_widget (new_combo_box);

            return new_combo_box;
        }


        private Gtk.Label new_label (Gtk.Grid panel, string text, int v_position, int h_position = 0) {
            // v_position and h_position is relative to the panel provided
            var new_label = new Gtk.Label (text);
            new_label.valign = Gtk.Align.CENTER;
            ((Gtk.Misc) new_label).xalign = 1;
            panel.attach (new_label, h_position, v_position, 1, 1);
            size_group[0].add_widget (new_label);

            return new_label;
        }

        private void show_panel_for_active_layout () {
            Layout active_layout = settings.layouts.get_layout (settings.layouts.active);
            advanced_settings.set_visible_panel_from_layout (active_layout.name);
        }
    }
}
