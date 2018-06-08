/*
 * Copyright (c) 2011-2016 elementary Developers (https://launchpad.net/elementary)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 */


namespace DateTime.Widgets {
    public class ControlHeader : Gtk.Box {
        public signal void left_clicked ();
        public signal void right_clicked ();
        public signal void center_clicked ();
        public ControlHeader () {
            Object (orientation : Gtk.Orientation.HORIZONTAL);
            var left_button = new Gtk.Button.from_icon_name ("pan-start-symbolic");
            var right_button = new Gtk.Button.from_icon_name ("pan-end-symbolic");
            var center_button = new Gtk.Button.with_label (new GLib.DateTime.now_local ().format (_("%B %Y")));
            CalendarModel.get_default ().parameters_changed.connect (() => {
                var date = CalendarModel.get_default ().month_start;
                center_button.set_label (date.format (_("%B %Y")));
            });
            left_button.clicked.connect (() => {
                left_clicked ();
            });
            right_button.clicked.connect (() => {
                right_clicked ();
            });
            center_button.clicked.connect (() => {
                center_clicked ();
            });
            left_button.can_focus = false;
            right_button.can_focus = false;
            center_button.can_focus = false;
            add (left_button);
            pack_end (right_button, false, false, 0);
            pack_end (center_button, true, true, 0);
            margin_bottom = 4;
            get_style_context ().add_class ("linked");
            set_size_request (-1, 30);
        }
    }
}
