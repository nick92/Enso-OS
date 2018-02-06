/*
* Copyright (c) 2014-2017 elementary LLC. (https://elementary.io)
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

namespace SwitchboardPlugUserAccounts.Widgets {
    public class PasswordEditor : Gtk.Grid {
        private Gtk.Entry current_pw_entry;
        private Gtk.Entry new_pw_entry;
        private Gtk.Entry confirm_pw_entry;
        private Gtk.CheckButton show_pw_check;
        private Gtk.LevelBar pw_level;
        private Gtk.Revealer error_revealer;
        private Gtk.Revealer error_new_revealer;
        private Gtk.Label error_new_label;

        private PasswordQuality.Settings pwquality;

        public bool is_authenticated { get; private set; default = false; }
        public bool is_valid { get; private set; default = false; }
        public int entry_width { get; construct; default = 200; }

        private signal void auth_changed ();
        public signal void validation_changed ();

        public PasswordEditor.from_width (int entry_width) {
            Object (entry_width: entry_width);
        }

        construct {
            pwquality = new PasswordQuality.Settings ();
            is_authenticated = get_permission ().allowed;
            /*
             * users who don't have superuser privileges will need to auth against passwd.
             * therefore they will need these UI elements created and displayed to set is_authenticated.
             */
            if (!is_authenticated) {
                current_pw_entry = new Gtk.Entry ();
                current_pw_entry.placeholder_text = _("Current Password");
                current_pw_entry.visibility = false;
                current_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
                current_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Press to authenticate"));

                var error_pw_label = new Gtk.Label ("<span font_size=\"small\">%s</span>".printf (_("Authentication failed")));
                error_pw_label.halign = Gtk.Align.END;
                error_pw_label.margin_top = 10;
                error_pw_label.use_markup = true;
                error_pw_label.get_style_context ().add_class ("error");

                error_revealer = new Gtk.Revealer ();
                error_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
                error_revealer.add (error_pw_label);

                current_pw_entry.changed.connect (() => {
                    if (current_pw_entry.text.length > 0) {
                        current_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "go-jump-symbolic");
                    }

                    error_revealer.reveal_child = false;
                });

                current_pw_entry.activate.connect (password_auth);
                current_pw_entry.icon_release.connect (password_auth);

                //use TAB to "activate" the GtkEntry for the current password
                this.key_press_event.connect ((e) => {
                    if (e.keyval == Gdk.Key.Tab && current_pw_entry.sensitive == true) {
                        password_auth ();
                    }
                    return false;
                });

                attach (current_pw_entry, 0, 0, 1, 1);
                attach (error_revealer, 0, 1, 1, 1);
            }

            error_new_label = new Gtk.Label ("");
            error_new_label.halign = Gtk.Align.END;
            error_new_label.justify = Gtk.Justification.RIGHT;
            error_new_label.margin_top = 10;
            error_new_label.max_width_chars = 30;
            error_new_label.use_markup = true;
            error_new_label.wrap = true;
            error_new_label.get_style_context ().add_class ("error");

            error_new_revealer = new Gtk.Revealer ();
            error_new_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            error_new_revealer.add (error_new_label);

            new_pw_entry = new Gtk.Entry ();
            new_pw_entry.placeholder_text = _("New Password");
            new_pw_entry.visibility = false;
            new_pw_entry.width_request = entry_width;

            if (!is_authenticated) {
                new_pw_entry.margin_top = 10;
            }

            new_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Password cannot be empty"));
            new_pw_entry.changed.connect (compare_passwords);

            pw_level = new Gtk.LevelBar.for_interval (0.0, 100.0);
            pw_level.margin_top = 10;
            pw_level.mode = Gtk.LevelBarMode.CONTINUOUS;
            pw_level.add_offset_value ("low", 50.0);
            pw_level.add_offset_value ("high", 75.0);
            pw_level.add_offset_value ("middle", 75.0);

            confirm_pw_entry = new Gtk.Entry ();
            confirm_pw_entry.margin_top = 10;
            confirm_pw_entry.placeholder_text = _("Confirm New Password");
            confirm_pw_entry.visibility = false;
            confirm_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Passwords do not match"));
            confirm_pw_entry.changed.connect (compare_passwords);

            show_pw_check = new Gtk.CheckButton.with_label (_("Show passwords"));
            show_pw_check.margin_top = 10;
            show_pw_check.clicked.connect (() => {
                if (show_pw_check.active) {
                    new_pw_entry.visibility = true;
                    confirm_pw_entry.visibility = true;
                } else {
                    new_pw_entry.visibility = false;
                    confirm_pw_entry.visibility = false;
                }
            });

            attach (new_pw_entry, 0, 2, 1, 1);
            attach (error_new_revealer, 0, 3, 1, 1);
            attach (pw_level, 0, 4, 1, 1);
            attach (confirm_pw_entry, 0, 5, 1, 1);
            attach (show_pw_check, 0, 6, 1, 1);

            auth_changed.connect (update_ui);
            show_all ();
        }

        private void update_ui () {
            if (is_authenticated) {
                current_pw_entry.sensitive = false;
                current_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
                current_pw_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Password accepted"));

                new_pw_entry.sensitive = true;
                new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
                new_pw_entry.grab_focus ();

                confirm_pw_entry.sensitive = true;
                show_pw_check.sensitive = true;
            }
        }

        private void compare_passwords () {
            bool is_obscure = false;

            if (new_pw_entry.text != "") {
                void* error;
                var quality = pwquality.check (new_pw_entry.text, current_pw_entry.text, null, out error);

                pw_level.value = quality;

                if (quality >= 0 && quality <= 50) {
                    pw_level.set_tooltip_text (_("Weak password strength"));
                } else if (quality > 50 && quality <= 75) {
                    pw_level.set_tooltip_text (_("Medium password strength"));
                } else if (quality > 75) {
                    pw_level.set_tooltip_text (_("Strong password strength"));
                }

                if (quality >= 0) {
                    is_obscure = true;
                    error_new_revealer.reveal_child = false;
                } else {
                    var pw_error = (PasswordQuality.Error) quality;
                    var error_string = pw_error.to_string (error);

                    error_new_label.label = "<span font_size=\"small\">%s</span>".printf (error_string);
                    error_new_revealer.reveal_child = true;

                    /* With admin privileges the new password doesn't need to pass the obscurity test */
                    is_obscure = is_authenticated;
                }
            }

            if (new_pw_entry.text == confirm_pw_entry.text && new_pw_entry.text != "" && is_obscure) {
                is_valid = true;
                new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
                confirm_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
            } else {
                is_valid = false;

                if (new_pw_entry.text != confirm_pw_entry.text) {
                    confirm_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
                } else {
                    confirm_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
                }

                if (new_pw_entry.text == "") {
                    new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
                    error_new_revealer.reveal_child = false;
                    confirm_pw_entry.sensitive = false;
                    confirm_pw_entry.text  = "";
                } else {
                    new_pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
                    confirm_pw_entry.sensitive = true;
                }
            }
            validation_changed ();
        }

        private void password_auth () {
            Passwd.passwd_authenticate (get_passwd_handler (true), current_pw_entry.text, (h, e) => {
                if (e != null) {
                    debug ("Authentication error: %s".printf (e.message));
                    error_revealer.reveal_child = true;
                    error_revealer.show_all ();
                    is_authenticated = false;
                    auth_changed ();
                } else {
                    debug ("User is authenticated for password change now");
                    is_authenticated = true;
                    auth_changed ();
                }
            });
        }

        public string? get_password () {
            if (is_valid) {
                return new_pw_entry.text;
            } else {
                return null;
            }
        }

        public void reset () {
            new_pw_entry.text = "";
            confirm_pw_entry.text = "";
        }
    }
}
