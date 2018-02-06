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
    public class MainView : Gtk.Paned {
        private UserListBox userlist;
        private Gtk.Stack content;
        private Gtk.ScrolledWindow scrolled_window;
        private ListFooter footer;
        private GuestSettingsView guest;

        public MainView () {
            Object (
                orientation: Gtk.Orientation.HORIZONTAL,
                position: 240
            );
        }

        construct {
            scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.expand = true;
            scrolled_window.hscrollbar_policy = Gtk.PolicyType.NEVER;

            footer = new ListFooter ();

            var sidebar = new Gtk.Grid ();
            sidebar.orientation = Gtk.Orientation.VERTICAL;
            sidebar.add (scrolled_window);
            sidebar.add (footer);

            guest = new GuestSettingsView ();

            content = new Gtk.Stack ();
            content.add_named (guest, "guest_session");

            var toast = new Granite.Widgets.Toast (_("Undo last user account removal"));
            toast.set_default_action (_("Undo"));

            var overlay = new Gtk.Overlay ();
            overlay.add (content);
            overlay.add_overlay (toast);

            pack1 (sidebar, false, false);
            pack2 (overlay, true, false);

            get_usermanager ().notify["is-loaded"].connect (update);

            if (get_usermanager ().is_loaded) {
                update ();
            }

            footer.send_undo_notification.connect (() => {
                toast.send_notification ();
            });

            footer.hide_undo_notification.connect (() => {
                toast.reveal_child = false;
            });

            toast.default_action.connect (() => {
                footer.undo_user_removal ();
            });
        }

        private void update () {
            get_usermanager ().user_added.connect (add_user_settings);
            get_usermanager ().user_removed.connect (remove_user_settings);

            userlist = new UserListBox ();
            userlist.row_selected.connect (userlist_selected);

            foreach (Act.User user in get_usermanager ().list_users ()) {
                add_user_settings (user);
            }

            scrolled_window.add (userlist);

            footer.removal_changed.connect (userlist.update_ui);

            footer.unfocused.connect (() => {
                content.set_visible_child_name (get_current_user ().get_user_name ());
                userlist.select_row (userlist.get_row_at_index (1));
            });

            guest.guest_switch_changed.connect (() => {
                userlist.update_guest ();
            });

            //auto select current user row in userlist widget
            userlist.select_row (userlist.get_row_at_index (0));
            show_all ();
        }

        private void add_user_settings (Act.User user) {
            debug ("Adding UserSettingsView Widget for User '%s'".printf (user.get_user_name ()));
            content.add_named (new UserSettingsView (user), user.get_user_name ());
        }

        private void remove_user_settings (Act.User user) {
            debug ("Removing UserSettingsView Widget for User '%s'".printf (user.get_user_name ()));
            content.remove (content.get_child_by_name (user.get_user_name ()));
        }

        private void userlist_selected (Gtk.ListBoxRow? user_item) {
            Act.User? user = null;
            if (user_item != null && user_item.name != "guest_session") {
                user = ((UserItem)user_item).user;
                content.set_visible_child_name (user.get_user_name ());
                footer.set_selected_user (user);
            } else if (user_item != null && user_item.name == "guest_session") {
                content.set_visible_child_name ("guest_session");
                footer.set_selected_user (null);
            }
        }
    }
}
