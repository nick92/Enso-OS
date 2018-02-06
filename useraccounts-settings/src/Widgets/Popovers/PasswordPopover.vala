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
    public class PasswordPopover : Gtk.Popover {
        public unowned Act.User user { get; construct; }
        public signal void request_password_change (Act.UserPasswordMode mode, string? new_password);

        public PasswordPopover (Gtk.Widget relative, Act.User user) {
            Object (
                modal: true,
                position: Gtk.PositionType.TOP,
                relative_to: relative,
                user: user
            );
        }

        construct {
            var pw_editor = new Widgets.PasswordEditor ();

            var button_change = new Gtk.Button.with_label (_("Change Password"));
            button_change.halign = Gtk.Align.END;
            button_change.sensitive = false;
            button_change.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

            var main_grid = new Gtk.Grid ();
            main_grid.margin = 12;
            main_grid.orientation = Gtk.Orientation.VERTICAL;
            main_grid.row_spacing = 24;
            main_grid.add (pw_editor);
            main_grid.add (button_change);

            add (main_grid);

            pw_editor.validation_changed.connect (() => {
                if (pw_editor.is_valid && pw_editor.is_authenticated) {
                    button_change.sensitive = true;
                } else {
                    button_change.sensitive = false;
                }
            });

            button_change.clicked.connect (() => {
                if (pw_editor.is_valid) {
                    request_password_change (Act.UserPasswordMode.REGULAR, pw_editor.get_password ());
                }

                hide ();
                destroy ();
            });
        }
    }
}
