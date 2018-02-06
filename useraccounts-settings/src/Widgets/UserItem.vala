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
    public class UserItem : Gtk.ListBoxRow {
        private Granite.Widgets.Avatar avatar;
        private Gtk.Label full_name_label;
        private Gtk.Label username_label;
        private Gtk.Label description_label;

        public weak Act.User user { get; construct; }

        public UserItem (Act.User user) {
            Object (user: user);
        }

        construct {
            full_name_label = new Gtk.Label ("");
            full_name_label.halign = Gtk.Align.START;
            full_name_label.get_style_context ().add_class ("h3");

            username_label = new Gtk.Label ("");
            username_label.halign = Gtk.Align.START;
            username_label.use_markup = true;
            username_label.ellipsize = Pango.EllipsizeMode.END;

            description_label = new Gtk.Label ("<span font_size=\"small\">(%s)</span>".printf (_("Administrator")));
            description_label.halign = Gtk.Align.START;
            description_label.use_markup = true;
            description_label.no_show_all = true;

            avatar = new Granite.Widgets.Avatar ();

            var grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.margin_left = 12;
            grid.column_spacing = 6;
            grid.attach (avatar, 0, 0, 1, 2);
            grid.attach (full_name_label, 1, 0, 2, 1);
            grid.attach (username_label, 1, 1, 1, 1);
            grid.attach (description_label, 2, 1, 1, 1);

            add (grid);

            user.changed.connect (update_ui);
            update_ui ();
        }

        public void update_ui () {
            try {
                var size = 32 * get_style_context ().get_scale ();
                var avatar_pixbuf = new Gdk.Pixbuf.from_file_at_scale (user.get_icon_file (), size, size, true);
                avatar.pixbuf = avatar_pixbuf;
            } catch (Error e) {
                avatar.show_default (32);
            }

            full_name_label.label = user.get_real_name ();
            username_label.label = "<span font_size=\"small\">%s</span>".printf (GLib.Markup.escape_text (user.get_user_name ()));

            if (user.get_account_type () == Act.UserAccountType.ADMINISTRATOR) {
                description_label.no_show_all = false;
            } else {
                description_label.hide ();
                description_label.no_show_all = true;
            }

            show_all ();
        }
    }
}
