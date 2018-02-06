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

namespace SwitchboardPlugUserAccounts {
    public class UserUtils {
        private unowned Act.User user;
        private unowned Widgets.UserSettingsView widget;

        public UserUtils (Act.User user, Widgets.UserSettingsView widget) {
            this.user = user;
            this.widget = widget;
        }

        public void change_avatar (Gdk.Pixbuf? new_pixbuf) {
            if (get_current_user () == user || get_permission ().allowed) {
                if (new_pixbuf != null) {
                    var path = Path.build_filename (Environment.get_tmp_dir (), "user-icon-0");
                    int i = 0;
                    while (FileUtils.test (path, FileTest.EXISTS)) {
                        path = Path.build_filename (Environment.get_tmp_dir (), "user-icon-%d".printf (i));
                        i++;
                    }
                    try {
                        debug ("Saving temporary avatar file to %s".printf (path));
                        new_pixbuf.savev (path, "png", {}, {});
                        debug ("Setting avatar icon file for %s from temporary file %s".printf (user.get_user_name (), path));
                        user.set_icon_file (path);
                        widget.update_avatar ();
                    } catch (Error e) {
                        critical (e.message);
                    }
                } else {
                    debug ("Setting no avatar icon file for %s".printf (user.get_user_name ()));
                    user.set_icon_file ("");
                    widget.update_avatar ();
                }
            }
        }

        public void change_full_name (string new_full_name) {
            if (get_current_user () == user || get_permission ().allowed) {
                if (new_full_name != user.get_real_name ()) {
                    debug ("Setting real name for %s to %s".printf (user.get_user_name (), new_full_name));
                    user.set_real_name (new_full_name);
                } else
                    widget.update_real_name ();
            }
        }

        public void change_user_type (int new_user_type) {
            if (get_permission ().allowed) {
                if (user.get_account_type () == Act.UserAccountType.STANDARD && new_user_type == 1) {
                    debug ("Setting account type for %s to Administrator".printf (user.get_user_name ()));
                    user.set_account_type (Act.UserAccountType.ADMINISTRATOR);
                } else if (user.get_account_type () == Act.UserAccountType.ADMINISTRATOR
                            && new_user_type == 0 && !is_last_admin (user)) {
                    debug ("Setting account type for %s to Standard".printf (user.get_user_name ()));
                    user.set_account_type (Act.UserAccountType.STANDARD);
                } else
                    widget.update_account_type ();
            }
        }

        public void change_language (string new_lang) {
            if (get_current_user () == user || get_permission ().allowed) {
                if (new_lang != "" && new_lang != user.get_language ()) {
                    debug ("Setting language for %s to %s".printf (user.get_user_name (), new_lang));
                    user.set_language (new_lang);
                } else {
                    widget.update_language ();
                    widget.update_region (null);
                }
            }
        }

        public void change_autologin (bool new_autologin) {
            if (get_permission ().allowed) {
                if (user.get_automatic_login () && !new_autologin) {
                    debug ("Removing automatic login for %s".printf (user.get_user_name ()));
                    user.set_automatic_login (false);
                } else if (!user.get_automatic_login () && new_autologin) {
                    debug ("Setting automatic login for %s".printf (user.get_user_name ()));
                    foreach (Act.User temp_user in get_usermanager ().list_users ()) {
                        if (temp_user.get_automatic_login () && temp_user != user)
                            temp_user.set_automatic_login (false);
                    }
                    user.set_automatic_login (true);
                }
            }
        }

        public void change_password (Act.UserPasswordMode mode, string? new_password) {
            if (get_permission ().allowed) {
                switch (mode) {
                    case Act.UserPasswordMode.REGULAR:
                        if (new_password != null) {
                            debug ("Setting new password for %s".printf (user.get_user_name ()));
                            user.set_password (new_password, "");
                        }
                        break;
                    case Act.UserPasswordMode.NONE:
                        debug ("Setting no password for %s".printf (user.get_user_name ()));
                        user.set_password_mode (Act.UserPasswordMode.NONE);
                        break;
                    case Act.UserPasswordMode.SET_AT_LOGIN:
                        debug ("Setting password mode to SET_AT_LOGIN for %s".printf (user.get_user_name ()));
                        user.set_password_mode (Act.UserPasswordMode.SET_AT_LOGIN);
                        break;
                    default: break;
                }
            } else if (user == get_current_user ()) {
                if (new_password != null) {
                    // we are going to assume that if a normal user calls this method,
                    // he is authenticated against the PasswdHandler
                    Passwd.passwd_change_password (get_passwd_handler (), new_password, (h, e) => {
                        if (e != null) {
                            warning ("Password change for %s failed".printf (user.get_user_name ()));
                            warning (e.message);
                            InfobarNotifier.get_default ().set_error (e.message);
                        } else
                            debug ("Setting new password for %s (user context)".printf (user.get_user_name ()));
                    });
                }
            }
        }

        public void change_lock () {
            if (get_permission ().allowed && get_current_user () != user) {
                if (user.get_locked ()) {
                    debug ("Unlocking user %s".printf (user.get_user_name ()));
                    user.set_password_mode (Act.UserPasswordMode.REGULAR);
                    user.set_locked (false);
                } else {
                    debug ("Locking user %s".printf (user.get_user_name ()));
                    user.set_automatic_login (false);
                    user.set_locked (true);
                }
            }
        }
    }
}
