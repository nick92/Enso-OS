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
    public class UserAccountWindow : Gtk.Window {
        private Gtk.Grid? main_grid;
        private Gtk.InfoBar infobar;
        private Gtk.InfoBar infobar_error;
        private Gtk.InfoBar infobar_reboot;
        private Gtk.LockButton lock_button;
        private Widgets.MainView main_view;
        static UserAccountsPlug app;

        public UserAccountWindow(){
            Gdk.Geometry geo = new Gdk.Geometry();
            geo.min_width = 600;
            geo.min_height = 500;
            geo.max_width = 1024;
            geo.max_height = 2048;

            this.set_geometry_hints(null, geo, Gdk.WindowHints.MIN_SIZE | Gdk.WindowHints.MAX_SIZE);

            this.title = "User Account Settings";

            this.add(get_widget ());
        }

        public Gtk.Widget get_widget () {
            if (main_grid != null) {
                return main_grid;
            }

            infobar_error = new Gtk.InfoBar ();
            infobar_error.message_type = Gtk.MessageType.ERROR;
            infobar_error.no_show_all = true;

            var error_label = new Gtk.Label ("");

            var error_content = infobar_error.get_content_area ();
            error_content.add (error_label);

            InfobarNotifier.get_default ().error_notified.connect (() => {
                if (InfobarNotifier.get_default ().is_error ()) {
                    infobar_error.no_show_all = false;
                    error_label.label = "%s: %s".printf (_("Password change failed"), InfobarNotifier.get_default ().get_error_message ());
                    infobar_error.show_all ();
                } else {
                    infobar_error.no_show_all = true;
                    infobar_error.hide ();
                }
            });

            infobar_reboot = new Gtk.InfoBar ();
            infobar_reboot.message_type = Gtk.MessageType.WARNING;
            infobar_reboot.no_show_all = true;

            var reboot_content = infobar_reboot.get_content_area ();
            reboot_content.add (new Gtk.Label (_("Guest session changes will not take effect until you restart your system")));

            InfobarNotifier.get_default ().reboot_notified.connect (() => {
                if (InfobarNotifier.get_default ().is_reboot ()) {
                    infobar_reboot.no_show_all = false;
                    infobar_reboot.show_all ();
                }
            });

            infobar = new Gtk.InfoBar ();
            infobar.message_type = Gtk.MessageType.INFO;

            lock_button = new Gtk.LockButton (get_permission ());

            var area = infobar.get_action_area () as Gtk.Container;
            area.add (lock_button);

            var content = infobar.get_content_area ();
            content.add (new Gtk.Label (_("Some settings require administrator rights to be changed")));

            main_view = new Widgets.MainView ();

            main_grid = new Gtk.Grid ();
            main_grid.attach (infobar_error, 0, 0, 1, 1);
            main_grid.attach (infobar_reboot, 0, 1, 1, 1);
            main_grid.attach (infobar, 0, 2, 1, 1);
            main_grid.attach (main_view, 0, 3, 1, 1);
            main_grid.show_all ();

            get_permission ().notify["allowed"].connect (() => {
                if (get_permission ().allowed) {
                    infobar.visible = false;
                }
            });

            return main_grid;
        }

        public void shown () {
            if (!get_permission ().allowed) {
                infobar.show_all ();
                infobar.visible = true;
            }
        }

        public void hidden () {
            try {
                foreach (Act.User user in get_removal_list ()) {
                    debug ("Removing user %s from system".printf (user.get_user_name ()));
                    get_usermanager ().delete_user (user, true);
                }
                debug ("Clearing removal list");
                clear_removal_list ();
            } catch (Error e) { critical (e.message); }

            if (get_permission ().allowed) {
                try {
                    debug ("Releasing administrative permissions");
                    get_permission ().release ();
                } catch (Error e) {
                    critical (e.message);
                }
            }
        }

        /**
         *  Quit from the program.
         */
        public bool main_quit () {
            //save_window_position ();
            this.destroy ();

            return false;
        }
    }
}
