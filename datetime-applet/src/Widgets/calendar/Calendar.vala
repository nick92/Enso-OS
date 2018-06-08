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
    public class Calendar : Gtk.Box {
        private const string CALENDAR_EXEC = "/usr/bin/gnome-calendar";

        ControlHeader heading;
        CalendarView cal;
        public signal void selection_changed (GLib.DateTime new_date);
        public signal void day_double_click (GLib.DateTime date);

        public GLib.DateTime? selected_date { get {
                return cal.selected_date;
            } set {
            }}

        public Calendar () {
            Object (orientation: Gtk.Orientation.VERTICAL, halign: Gtk.Align.CENTER, valign: Gtk.Align.CENTER, can_focus: false);
            this.margin_start = 10;
            this.margin_end = 10;
            heading = new ControlHeader ();
            cal = new CalendarView ();
            cal.selection_changed.connect ((date) => {
                selection_changed (date);
            });
            cal.on_event_add.connect ((date) => {
                show_date_in_maya (date);
                day_double_click (date);
            });
            heading.left_clicked.connect (() => {
                CalendarModel.get_default ().change_month (-1);
            });
            heading.right_clicked.connect (() => {
                CalendarModel.get_default ().change_month (1);
            });
            heading.center_clicked.connect (() => {
                cal.today ();
            });
            add (heading);
            add (cal);
        }

        public void show_today () {
            cal.today ();
        }

        // TODO: As far as maya supports it use the Dbus Activation feature to run the calendar-app.
        public void show_date_in_maya (GLib.DateTime date) {
            var iso_date_string = date.format ("%F");
            var command = CALENDAR_EXEC + @" --date $iso_date_string";

            try {
                var appinfo = AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.NONE);
                appinfo.launch_uris (null, null);
            } catch (GLib.Error e) {
                warning ("Unable to start calendar, error: %s", e.message);
            }
        }
    }
}
