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
    public class UserListBox : Gtk.ListBox {
        private Gtk.Label       my_account_label;
        private Gtk.Label       other_accounts_label;
        private Gtk.ListBoxRow  guest_session_row;
        private Gtk.Label       guest_description_label;

        public UserListBox () { 
            selection_mode = Gtk.SelectionMode.SINGLE;
            get_usermanager ().user_added.connect (update_ui);
            get_usermanager ().user_removed.connect (update_ui);
            set_header_func (update_headers);

            build_ui ();
            show_all ();
        }

        private void build_ui () {
            my_account_label = new Gtk.Label (_("My Account"));
            my_account_label.halign = Gtk.Align.START;
            my_account_label.get_style_context ().add_class ("h4");

            other_accounts_label = new Gtk.Label (_("Other Accounts"));
            other_accounts_label.halign = Gtk.Align.START;
            other_accounts_label.get_style_context ().add_class ("h4");

            //only build the guest session list entry / row when lightDM is X11's display manager
            if (get_display_manager () == "lightdm") {
                build_guest_session_row ();
                debug ("LightDM found as display manager. Loading guest session settings");
            } else
                debug ("Unsupported display manager found. Guest session settings will be hidden");

            update_ui ();
        }

        public void update_ui () {
            List<weak Gtk.Widget> userlist_items = get_children ();

            foreach (unowned Gtk.Widget useritem in userlist_items)
                remove (useritem);

            insert (new UserItem (get_current_user ()), 0);
            int pos = 1;
            foreach (unowned Act.User temp_user in get_usermanager ().list_users ()) {
                if (get_current_user () != temp_user && !check_removal (temp_user)) {
                    insert (new UserItem (temp_user), pos);
                    pos++;
                }
            }

            insert (guest_session_row, pos);

            show_all ();
        }

        public void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
                if (row == get_row_at_index (0))
                    row.set_header (my_account_label);
                else if (row == get_row_at_index (1))
                    row.set_header (other_accounts_label);
        }

        public void update_guest () {
            string state_string = _("Enabled");
            bool state = get_guest_session_state ("show");

            if (!state)
                state_string = _("Disabled");

            guest_description_label.set_label ("<span font_size=\"small\">%s</span>".printf (state_string));
        }

        private void build_guest_session_row () {
            guest_session_row = new Gtk.ListBoxRow ();
            guest_session_row.name = "guest_session";
            var row_grid = new Gtk.Grid ();
            row_grid.margin = 6;
            row_grid.margin_left = 12;
            row_grid.column_spacing = 6;
            guest_session_row.add (row_grid);

            var avatar = new Granite.Widgets.Avatar.with_default_icon (32);

            var full_name_label = new Gtk.Label (_("Guest Session"));
            full_name_label.halign = Gtk.Align.START;
            full_name_label.get_style_context ().add_class ("h3");

            guest_description_label = new Gtk.Label (null);
            guest_description_label.halign = Gtk.Align.START;
            guest_description_label.use_markup = true;

            row_grid.attach (avatar, 0, 0, 1, 2);
            row_grid.attach (full_name_label, 1, 0, 1, 1);
            row_grid.attach (guest_description_label, 1, 1, 1, 1);

            update_guest ();
        }
    }
}
