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
    public class ListFooter : Gtk.ActionBar {
        private Gtk.Button button_add;
        private Gtk.Button button_remove;

        private Act.User? selected_user = null;

        public signal void removal_changed ();
        public signal void unfocused ();
        public signal void send_undo_notification ();
        public signal void hide_undo_notification ();

        construct {
            button_add = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            button_add.sensitive = false;
            button_add.tooltip_text = _("Create user account");

            button_remove = new Gtk.Button.from_icon_name ("list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            button_remove.sensitive = false;
            button_remove.tooltip_text = _("Remove user account and its data");

            get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
            add (button_add);
            add (button_remove);

            button_add.clicked.connect (() => {
                var new_user = new Widgets.NewUserPopover (button_add);
                new_user.show_all ();
                new_user.request_user_creation.connect (create_new_user);
            });

            button_remove.clicked.connect (mark_user_removal);

            get_permission ().notify["allowed"].connect (update_ui);
            get_usermanager ().user_removed.connect (update_ui);
        }

        public void undo_user_removal () {
            undo_removal ();
            removal_changed ();
            update_ui ();
        }

        private void update_ui () {
            if (get_permission ().allowed) {
                button_add.sensitive = true;
            } else {
                button_add.sensitive = false;
                button_remove.sensitive = false;
                hide_undo_notification ();
                return;
            }

            if (selected_user == null) {
                button_remove.sensitive = false;
                button_remove.tooltip_text = "";
            } else if (selected_user != get_current_user () && !is_last_admin (selected_user) && !selected_user.get_automatic_login ()) {
                button_remove.sensitive = true;
                button_remove.tooltip_text = _("Remove user account and its data");
            } else {
                button_remove.sensitive = false;
                button_remove.set_tooltip_text (_("You cannot remove your own user account"));
            }

            if (get_removal_list ().last () == null) {
                hide_undo_notification ();
            }
        }

        public void set_selected_user (Act.User? _user) {
            selected_user =_user;
            if (selected_user != null)
                selected_user.changed.connect (update_ui);
            update_ui ();
        }

        private void mark_user_removal () {
            debug ("Marking user %s for removal".printf (selected_user.get_user_name ()));
            mark_removal (selected_user);
            removal_changed ();
            selected_user = null;
            unfocused ();
            update_ui ();
            send_undo_notification ();
        }
    }
}
