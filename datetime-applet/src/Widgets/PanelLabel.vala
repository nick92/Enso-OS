/*
 * Copyright (c) 2011-2015 Wingpanel Developers (http://launchpad.net/wingpanel)
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

public class DateTime.Widgets.PanelLabel : Gtk.Grid {
    private Gtk.Label date_label;
    private Gtk.Label time_label;

    private ClockSettings clockSettings;
    private bool use24HSFormat = false;

    public PanelLabel () {
        clockSettings = new ClockSettings ();
        this.use24HSFormat = (clockSettings.clock_format == "24h");

        clockSettings.notify["clock-format"].connect (() => {
            if (clockSettings.clock_format == "24h") {
                this.use24HSFormat = true;
            } else {
                this.use24HSFormat = false;
            }

            update_labels ();
        });

        update_labels ();

        Services.TimeManager.get_default ().minute_changed.connect (update_labels);
    }

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        column_spacing = 12;
        margin_bottom = 12;
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;

        date_label = new Gtk.Label (null);
        time_label = new Gtk.Label (null);

        date_label.get_style_context ().add_class ("header");
        time_label.get_style_context ().add_class ("header");
        

        add (time_label);
        add (date_label);
    }

    private void update_labels () {
        /// TRANSLATORS: Date format in the panel following https://valadoc.org/glib-2.0/GLib.DateTime.format.html */
        date_label.set_label (Services.TimeManager.get_default ().format (_("%A, %e %B %Y")));
        date_label.get_style_context ().add_class ("h2");

        if (use24HSFormat) {
            time_label.set_label (Services.TimeManager.get_default ().format ("%H:%M"));
        } else {
            /// TRANSLATORS: Time format in the panel following https://valadoc.org/glib-2.0/GLib.DateTime.format.html */
            time_label.set_label (Services.TimeManager.get_default ().format (_("%l:%M %p")));
        }
        time_label.get_style_context ().add_class ("h2");
    }
}
