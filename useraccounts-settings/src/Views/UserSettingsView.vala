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
    public class UserSettingsView : Gtk.Grid {
        public weak Act.User user { get; construct; }

        private UserUtils           utils;
        private DeltaUser           delta_user;

        private Gtk.ListStore       language_store;
        private Gtk.ListStore       region_store;

        private Granite.Widgets.Avatar avatar;
        private Gdk.Pixbuf?         avatar_pixbuf;
        private Gtk.ToggleButton    avatar_button;
        private Gtk.Entry           full_name_entry;
        private Gtk.ToggleButton    password_button;
        private Gtk.Button          enable_user_button;
        private Gtk.ComboBoxText    user_type_box;
        private Gtk.ComboBox        language_box;
        private Gtk.Revealer        region_revealer;
        private Gtk.ComboBox        region_box;
        private Gtk.Button          language_button;
        private Gtk.Switch          autologin_switch;

        //lock widgets
        private Gtk.Image           full_name_lock;
        private Gtk.Image           user_type_lock;
        private Gtk.Image           language_lock;
        private Gtk.Image           autologin_lock;
        private Gtk.Image           password_lock;
        private Gtk.Image           enable_lock;

        private Gee.HashMap<string, string> default_regions;

        private const string NO_PERMISSION_STRING = _("You do not have permission to change this");
        private const string CURRENT_USER_STRING = _("You cannot change this for the currently active user");
        private const string LAST_ADMIN_STRING = _("You cannot remove the last administrator's privileges");

        public UserSettingsView (Act.User user) {
            Object (
                column_spacing: 12,
                halign: Gtk.Align.CENTER,
                margin: 24,
                row_spacing: 6,
                user: user
            );
        }

        construct {
            utils = new UserUtils (user, this);
            delta_user = new DeltaUser (user);

            default_regions = get_default_regions ();

            avatar_button = new Gtk.ToggleButton ();
            avatar_button.halign = Gtk.Align.END;
            avatar_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            avatar_button.toggled.connect (() => {
                if (avatar_button.active) {
                    InfobarNotifier.get_default ().unset_error ();
                    AvatarPopover avatar_popover = new AvatarPopover (avatar_button, user, utils);
                    avatar_popover.show_all ();
                    avatar_popover.hide.connect (() => { avatar_button.active = false;});
                }
            });

            full_name_entry = new Gtk.Entry ();
            full_name_entry.valign = Gtk.Align.CENTER;
            full_name_entry.get_style_context ().add_class ("h3");
            full_name_entry.activate.connect (() => {
                InfobarNotifier.get_default ().unset_error ();
                utils.change_full_name (full_name_entry.get_text ());
            });

            var user_type_label = new Gtk.Label (_("Account type:"));
            user_type_label.halign = Gtk.Align.END;

            user_type_box = new Gtk.ComboBoxText ();
            user_type_box.append_text (_("Standard"));
            user_type_box.append_text (_("Administrator"));
            user_type_box.changed.connect (() => {
                InfobarNotifier.get_default ().unset_error ();
                utils.change_user_type (user_type_box.get_active ());
            });

            var lang_label = new Gtk.Label (_("Language:"));
            lang_label.halign = Gtk.Align.END;

            if (user != get_current_user ()) {
                language_box = new Gtk.ComboBox ();
                language_box.set_sensitive (false);
                language_box.changed.connect (() => {
                    InfobarNotifier.get_default ().unset_error ();

                    Gtk.TreeIter? iter;
                    Value cell;

                    language_box.get_active_iter (out iter);
                    language_store.get_value (iter, 0, out cell);

                    if (get_regions ((string)cell).size == 0) {
                        region_revealer.set_reveal_child (false);
                        if (user.get_language () != (string)cell)
                            utils.change_language ((string)cell);
                    } else {
                        region_revealer.set_reveal_child (true);
                        region_box.set_no_show_all (false);
                        update_region ((string)cell);
                    }
                });
                attach (language_box, 1, 2, 1, 1);

                var renderer = new Gtk.CellRendererText ();
                language_box.pack_start (renderer, true);
                language_box.add_attribute (renderer, "text", 1);

                region_box = new Gtk.ComboBox ();
                region_box.set_sensitive (false);
                region_box.changed.connect (() => {
                    InfobarNotifier.get_default ().unset_error ();

                    string new_language;
                    Gtk.TreeIter? iter;
                    Value cell;

                    language_box.get_active_iter (out iter);
                    language_store.get_value (iter, 0, out cell);
                    new_language = (string)cell;

                    region_box.get_active_iter (out iter);
                    region_store.get_value (iter, 0, out cell);
                    new_language += "_%s".printf ((string)cell);

                    if (new_language != "" && new_language != user.get_language ())
                        utils.change_language (new_language);
                });

                region_revealer = new Gtk.Revealer ();
                region_revealer.set_transition_type (Gtk.RevealerTransitionType.SLIDE_DOWN);
                region_revealer.set_reveal_child (true);
                region_revealer.add (region_box);
                attach (region_revealer, 1, 3, 1, 1);

                renderer = new Gtk.CellRendererText ();
                region_box.pack_start (renderer, true);
                region_box.add_attribute (renderer, "text", 1);

            } else {
                language_button = new Gtk.LinkButton.with_label ("settings://language", "Language");
                language_button.halign = Gtk.Align.START;
                language_button.set_tooltip_text (_("Click to switch to Language & Locale Settings"));
                attach (language_button, 1, 2, 1, 1);
            }

            var login_label = new Gtk.Label (_("Log In automatically:"));
            login_label.halign = Gtk.Align.END;
            login_label.margin_top = 20;

            autologin_switch = new Gtk.Switch ();
            autologin_switch.halign = Gtk.Align.START;
            autologin_switch.margin_top = 24;
            autologin_switch.notify["active"].connect (() => utils.change_autologin (autologin_switch.get_active ()));

            var change_password_label = new Gtk.Label (_("Password:"));
            change_password_label.halign = Gtk.Align.END;

            password_button = new Gtk.ToggleButton ();
            password_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            password_button.halign = Gtk.Align.START;
            password_button.toggled.connect (() => {
                if (password_button.active) {
                    InfobarNotifier.get_default ().unset_error ();
                    Widgets.PasswordPopover pw_popover = new Widgets.PasswordPopover (password_button, user);
                    pw_popover.show_all ();
                    pw_popover.request_password_change.connect (utils.change_password);
                    pw_popover.hide.connect (() => { password_button.active = false;});
                }
            });

            enable_user_button = new Gtk.Button ();
            enable_user_button.clicked.connect (utils.change_lock);
            enable_user_button.set_sensitive (false);
            enable_user_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

            full_name_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
            full_name_lock.tooltip_text = NO_PERMISSION_STRING;

            user_type_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
            user_type_lock.tooltip_text = NO_PERMISSION_STRING;

            language_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
            language_lock.tooltip_text = NO_PERMISSION_STRING;

            autologin_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
            autologin_lock.margin_top = 20;
            autologin_lock.tooltip_text = NO_PERMISSION_STRING;

            password_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
            password_lock.tooltip_text = NO_PERMISSION_STRING;

            enable_lock = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.BUTTON);
            enable_lock.tooltip_text = NO_PERMISSION_STRING;

            attach (avatar_button, 0, 0, 1, 1);
            attach (full_name_entry, 1, 0, 1, 1);
            attach (user_type_label,0, 1, 1, 1);
            attach (user_type_box, 1, 1, 1, 1);
            attach (lang_label, 0, 2, 1, 1);
            attach (login_label, 0, 4, 1, 1);
            attach (autologin_switch, 1, 4, 1, 1);
            attach (change_password_label, 0, 5, 1, 1);
            attach (password_button, 1, 5, 1, 1);
            attach (enable_user_button, 1, 6, 1, 1);
            attach (full_name_lock, 2, 0, 1, 1);
            attach (user_type_lock, 2, 1, 1, 1);
            attach (language_lock, 2, 2, 1, 2);
            attach (autologin_lock, 2, 4, 1, 1);
            attach (password_lock, 2, 5, 1, 1);
            attach (enable_lock, 2, 6, 1, 1);

            update_ui ();
            get_permission ().notify["allowed"].connect (update_ui);

            user.changed.connect (update_ui);
        }

        public void update_ui () {
            var allowed = get_permission ().allowed;
            var current_user = get_current_user () == user;
            var last_admin = is_last_admin (user);

            if (!allowed) {
                user_type_box.set_sensitive (false);
                password_button.set_sensitive (false);
                autologin_switch.set_sensitive (false);
                enable_user_button.set_sensitive (false);

                user_type_lock.set_opacity (0.5);
                autologin_lock.set_opacity (0.5);
                password_lock.set_opacity (0.5);
                enable_lock.set_opacity (0.5);

                user_type_lock.tooltip_text = NO_PERMISSION_STRING;
                enable_lock.tooltip_text = NO_PERMISSION_STRING;
            } else if (current_user) {
                user_type_lock.tooltip_text = CURRENT_USER_STRING;
                enable_lock.tooltip_text = CURRENT_USER_STRING;
            } else if (last_admin) {
                user_type_lock.tooltip_text = LAST_ADMIN_STRING;
                enable_lock.tooltip_text = LAST_ADMIN_STRING;
            }

            if (current_user || allowed) {
                avatar_button.set_sensitive (true);
                full_name_entry.set_sensitive (true);
                full_name_lock.set_opacity (0);
                language_lock.set_opacity (0);

                if (!user.get_locked ()) {
                    password_button.set_sensitive (true);
                    password_lock.set_opacity (0);
                }

                if (allowed) {
                    if (!user.get_locked ()) {
                        autologin_switch.set_sensitive (true);
                        autologin_lock.set_opacity (0);
                    }
                    if (!last_admin && !current_user) {
                        user_type_box.set_sensitive (true);
                        user_type_lock.set_opacity (0);
                    }
                }

                if (!current_user) {
                    language_box.set_sensitive (true);
                    region_box.set_sensitive (true);
                }
            } else {
                avatar_button.set_sensitive (false);
                full_name_entry.set_sensitive (false);
                full_name_lock.set_opacity (0.5);
                language_lock.set_opacity (0.5);

                if (!current_user) {
                    language_box.set_sensitive (false);
                    region_box.set_sensitive (false);
                }
            }

            if (allowed && !current_user && !last_admin) {
                enable_user_button.set_sensitive (true);
                enable_lock.set_opacity (0);
            }

            //only update widgets if the user property has changed since last ui update
            if (delta_user.real_name != user.get_real_name ()) {
                update_real_name ();
            }

            if (delta_user.icon_file != user.get_icon_file ()) {
                update_avatar ();
            }

            if (delta_user.account_type != user.get_account_type ()) {
                update_account_type ();
            }

            if (delta_user.password_mode != user.get_password_mode ()) {
                update_password ();
            }

            if (delta_user.automatic_login != user.get_automatic_login ()) {
                update_autologin ();
            }

            if (delta_user.locked != user.get_locked ()) {
                update_lock_state ();
            }

            if (delta_user.language != user.get_language ()) {
                update_language ();
            }

            delta_user.update ();
            show_all ();
        }

        public void update_real_name () {
            full_name_entry.set_text (user.get_real_name ());
        }

        public void update_account_type () {
            if (user.get_account_type () == Act.UserAccountType.ADMINISTRATOR)
                user_type_box.set_active (1);
            else
                user_type_box.set_active (0);
        }

        public void update_autologin () {
            if (user.get_automatic_login () && !autologin_switch.get_active ())
                autologin_switch.set_active (true);
            else if (!user.get_automatic_login () && autologin_switch.get_active ())
                autologin_switch.set_active (false);
        }

        public void update_lock_state () {
            if (user.get_locked ()) {
                enable_user_button.set_label (_("Enable User Account"));
                enable_user_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            } else if (!user.get_locked ())
                enable_user_button.set_label (_("Disable User Account"));
        }

        public void update_password () {
            if (user.get_password_mode () == Act.UserPasswordMode.NONE)
                password_button.set_label (_("None set"));
            else
                password_button.set_label ("**********");
        }

        public void update_avatar () {
            try {
                var size = 72 * get_style_context ().get_scale ();
                avatar_pixbuf = new Gdk.Pixbuf.from_file_at_scale (user.get_icon_file (), size, size, true);
                if (avatar == null)
                    avatar = new Granite.Widgets.Avatar.from_pixbuf (avatar_pixbuf);
                else
                    avatar.pixbuf = avatar_pixbuf;
            } catch (Error e) {
                avatar = new Granite.Widgets.Avatar.with_default_icon (72);
            }
            avatar_button.set_image (avatar);
        }

        public void update_language () {
            if (user != get_current_user ()) {
                var languages = get_languages ();
                language_store = new Gtk.ListStore (2, typeof (string), typeof (string));
                Gtk.TreeIter iter;

                language_box.set_model (language_store);

                foreach (string language in languages) {
                    language_store.insert (out iter, 0);
                    language_store.set (iter, 0, language, 1, Gnome.Languages.get_language_from_code (language, null));
                    if (user.get_language ().slice (0, 2) == language)
                        language_box.set_active_iter (iter);
                }

            } else {
                var language = Gnome.Languages.get_language_from_code (user.get_language ().slice (0, 2), null);
                language_button.set_label (language);
            }
        }

        public void update_region (string? language) {
            Gtk.TreeIter? iter;

            if (language == null) {
                Value cell;

                language_box.get_active_iter (out iter);
                language_store.get_value (iter, 0, out cell);
                language = (string)cell;
            }

            var regions = get_regions (language);
            region_store = new Gtk.ListStore (2, typeof (string), typeof (string));
            bool iter_set = false;

            region_box.set_model (region_store);

            foreach (string region in regions) {
                region_store.insert (out iter, 0);
                region_store.set (iter, 0, region, 1, Gnome.Languages.get_country_from_code (region, null));
                if (user.get_language ().length == 5 && user.get_language ().slice (3, 5) == region) {
                    region_box.set_active_iter (iter);
                    iter_set = true;
                }
            }

            if (!iter_set) {
                Gtk.TreeIter? active_iter = null;

                Gtk.TreeModelForeachFunc check_region_store = (model, path, iter) => {
                    Value cell;
                    region_store.get_value (iter, 0, out cell);

                    if (default_regions.has_key (language)
                    && default_regions.@get (language) == "%s_%s".printf (language, (string)cell))
                        active_iter = iter;

                    return false;
                };
                region_store.foreach (check_region_store);
                if (active_iter == null)
                    region_store.get_iter_first (out active_iter);

                region_box.set_active_iter (active_iter);
            }
        }
    }
}
