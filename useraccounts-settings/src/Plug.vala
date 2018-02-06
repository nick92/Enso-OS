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
* Authored by: Corentin Noël <corentin@elementary.io>
*              Marvin Beckers <beckersmarvin@gmail.com>
*/

namespace SwitchboardPlugUserAccounts {
    public static UserAccountsPlug plug;

    public class UserAccountsPlug : Gtk.Application {
        static UserAccountsPlug app;
        UserAccountWindow window = null;

        //translatable string for org.pantheon.user-accounts.administration policy
        public const string policy_message = _("Authentication is required to change user data");

        public UserAccountsPlug () {
            Object (application_id: "com.enso.settings.useraccount",
            flags: ApplicationFlags.FLAGS_NONE);
            var settings = new Gee.TreeMap<string, string?> (null, null);
            settings.set ("accounts", null);
            /*Object (category: Category.SYSTEM,
                code_name: "system-pantheon-useraccounts",
                display_name: _("User Accounts"),
                description: _("Manage account permissions and configure user names, passwords, and photos"),
                icon: "system-users",
                supported_settings: settings);*/
        }

        public static int main (string[] args) {
            Intl.setlocale (LocaleCategory.ALL, "");
            Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");
            Intl.textdomain (Build.GETTEXT_PACKAGE);

            plug = new UserAccountsPlug ();

            if (args[1] == "-s") {
                return 0;
            }

            return plug.run (args);
        }

        protected override void activate () {
            if (window != null) {
                window.present ();
                return;
            }

            window = new UserAccountWindow ();
            window.set_application (this);
            window.delete_event.connect(window.main_quit);
            window.show_all ();
        }

        /*public void search_callback (string location) { }

        // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
        public async Gee.TreeMap<string, string> search (string search) {
            return new Gee.TreeMap<string, string> (null, null);
        }*/
    }
}
