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
*
* Authored by: Marvin Beckers <beckersmarvin@gmail.com>
*/

namespace SwitchboardPlugUserAccounts {
    public class DeltaUser : Object {
        private weak Act.User   user;

        public string?               real_name { public get; private set; }
        public Act.UserAccountType?  account_type { public get; private set; }
        public bool?                 automatic_login { public get; private set; }
        public bool?                 locked { public get; private set; }
        public Act.UserPasswordMode? password_mode { public get; private set; }
        public string?               icon_file { public get; private set; }
        public string?               language { public get; private set; }

        public DeltaUser (Act.User user) {
            this.user = user;

            //set all properties to null to be sure widgets will be updated on first load
            real_name = null;
            account_type = null;
            automatic_login = null;
            locked = null;
            password_mode = null;
            icon_file = null;
            language = null;
        }

        public void update () {
            real_name = user.get_real_name ();
            account_type = user.get_account_type ();
            automatic_login = user.get_automatic_login ();
            locked = user.get_locked ();
            password_mode = user.get_password_mode ();
            icon_file = user.get_icon_file ();
            language = user.get_language ();
        }
    }

    public static string get_display_manager () {
        //TODO: add file location for different, non-debian-based distros
        string file = "/etc/X11/default-display-manager";
        string output = "";

        try {
            FileUtils.get_contents (file, out output);
        } catch (Error e) {
            warning (e.message);
            return "";
        }

        output = output.slice (output.last_index_of ("/") + 1, output.length).chomp ();
        return output;
    }

    private static string[]? installed_languages = null;

    public static string[]? get_installed_languages () {
        if (installed_languages != null)
            return installed_languages;

        string output;
        int status;

        try {
            Process.spawn_sync (null,
                {"/usr/share/language-tools/language-options" , null},
                Environ.get (),
                SpawnFlags.SEARCH_PATH,
                null,
                out output,
                null,
                out status);

                installed_languages = output.split("\n");
                return installed_languages;
        } catch (Error e) {
            critical (e.message);
            return null;
        }
    }

    private static Gee.HashMap<string, string>? default_regions;

    public static unowned Gee.HashMap<string, string>? get_default_regions () {
        if (default_regions != null)
            return default_regions;

        default_regions = new Gee.HashMap<string, string> ();
        string file = "/usr/share/language-tools/main-countries";
        string? output = "";
        try {
            FileUtils.get_contents (file, out output);
        } catch (Error e) {
            warning (e.message);
        }

        var output_array = output.split ("\n");
        foreach (string line in output_array) {
            if (line != "" && line.index_of ("#") == -1) {
                var line_array = line.split ("\t");
                default_regions.@set (line_array[0], line_array[1]);
            }
        }

        return default_regions;
    }

    public static Gee.ArrayList<string> get_languages () {
        Gee.ArrayList<string> languages = new Gee.ArrayList<string> ();
        foreach (string locale in get_installed_languages ()) {
            string code = locale.slice (0, 2);
            if (!languages.contains (code))
                languages.add (code);
        }

        return languages;
    }

    public static Gee.ArrayList<string> get_regions (string language) {
        Gee.ArrayList<string> regions = new Gee.ArrayList<string> ();
            foreach (string locale in get_installed_languages ()) {
                if (locale.length == 5) {
                    string code = locale.slice (0, 2);
                    string region = locale.slice (3, 5);

                    if (!regions.contains (region) && code == language)
                        regions.add (region);
                }
            }
        return regions;
    }

    private static Polkit.Permission? permission = null;

    public static Polkit.Permission? get_permission () {
        if (permission != null)
            return permission;
        try {
            permission = new Polkit.Permission.sync ("org.pantheon.switchboard.user-accounts.administration", new Polkit.UnixProcess (Posix.getpid ()));
            return permission;
        } catch (Error e) {
            critical (e.message);
            return null;
        }
    }

    private static Act.UserManager? usermanager = null;

    public static unowned Act.UserManager? get_usermanager () {
        if (usermanager != null && usermanager.is_loaded)
            return usermanager;

        usermanager = Act.UserManager.get_default ();
        return usermanager;
    }

    private static Act.User? current_user = null;

    public static unowned Act.User? get_current_user () {
        if (current_user != null)
            return current_user;

        current_user = get_usermanager ().get_user (GLib.Environment.get_user_name ());
        return current_user;
    }

    private static List<Act.User>? removal_list = null;

    public static unowned List<Act.User> get_removal_list () {
        if (removal_list != null)
            return removal_list;

        removal_list = new List<Act.User> ();
        return removal_list;
    }

    public static void clear_removal_list () {
        removal_list = null;
    }

    public static void mark_removal (Act.User user) {
        if (removal_list == null)
            get_removal_list ();

        removal_list.append (user);
    }

    public static void undo_removal () {
        if (removal_list != null && removal_list.last () != null) {
            removal_list.remove (removal_list.last ().data);
        }
    }

    public static bool check_removal (Act.User user) {
        if (removal_list != null && removal_list.last () != null) {
            unowned List<Act.User>? find = removal_list.find (user);
            if (find != null)
                return true;
            else
                return false;
        }
        return false;
    }

    public static bool is_last_admin (Act.User? user) {
        if (user != null) {
            foreach (unowned Act.User temp_user in get_usermanager ().list_users ()) {
                if (temp_user != user && temp_user.get_account_type () == Act.UserAccountType.ADMINISTRATOR)
                    return false;
            }
            return true;
        }
        return false;
    }

    public static bool is_valid_username (string username) {
        try {
            if (new Regex("^[a-z]+[a-z0-9]*$").match (username))
                return true;
            return false;
        } catch (Error e) {
            critical (e.message);
            return false;
        }
    }

    public static bool is_taken_username (string username) {
        foreach (unowned Act.User user in get_usermanager ().list_users ()) {
            if (user.get_user_name () == username)
                return true;
        }
        return false;
    }

    public static string gen_username (string fullname) {
        string username = "";
        bool met_alpha = false;

        foreach (char c in fullname.to_ascii ().to_utf8 ()) {
            if (c.isalpha ()) {
                username += c.to_string ().down ();
                met_alpha = true;
            } else if (c.isdigit () && met_alpha) {
                username += c.to_string ();
            }
        }

        return username;
    }

    public static void create_new_user (string fullname, string username,
    Act.UserAccountType usertype, Act.UserPasswordMode mode, string? password = null) {
        if (get_permission ().allowed) {
            try {
                Act.User created_user = get_usermanager ().create_user (username, fullname, usertype);

                get_usermanager ().user_added.connect ((user) => {
                    if (user == created_user) {
                        created_user.set_locked (false);
                            if (mode == Act.UserPasswordMode.REGULAR && password != null)
                                created_user.set_password (password, "");
                            else if (mode == Act.UserPasswordMode.NONE)
                                created_user.set_password_mode (Act.UserPasswordMode.NONE);
                            else if (mode == Act.UserPasswordMode.SET_AT_LOGIN)
                                created_user.set_password_mode (Act.UserPasswordMode.SET_AT_LOGIN);
                    }
                });
            } catch (Error e) {
                critical ("Creation of user '%s' failed".printf (username));
            }
        }
    }

    private static Passwd.Handler? passwd_handler;

    public static unowned Passwd.Handler? get_passwd_handler (bool _force_new = false) {
        if (passwd_handler != null && !_force_new)
            return passwd_handler;

        passwd_handler = new Passwd.Handler ();
        return passwd_handler;
    }

    public static bool get_guest_session_state (string option) {
        string output;
        int status;

        try {
            var cli = "%s/guest-session-toggle".printf (Build.PKGDATADIR);
            Process.spawn_sync (null,
                {cli, "--%s".printf (option)},
                Environ.get (),
                SpawnFlags.SEARCH_PATH,
                null,
                out output,
                null,
                out status);

            return output == "on\n";
        } catch (Error e) {
            warning (e.message);
            return false;
        }
    }

    public static void set_guest_session_state (string option) {
        if (get_permission ().allowed) {
            string output;
            int status;

            try {
                var cli = "%s/guest-session-toggle".printf (Build.PKGDATADIR);
                Process.spawn_sync (null,
                    {"pkexec", cli, "--%s".printf (option)},
                    Environ.get (),
                    SpawnFlags.SEARCH_PATH,
                    null,
                    out output,
                    null,
                    out status);
            } catch (Error e) {
                warning (e.message);
            }
        }
    }
}
