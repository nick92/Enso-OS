/*
 * Copyright 2019 elementary, Inc. (https://elementary.io)
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

public class DateTime.EventRow : Gtk.ListBoxRow {
    public GLib.DateTime date { get; construct; }
    public unowned ICal.Component component { get; construct; }
    public unowned E.SourceCalendar cal { get; construct; }

    public GLib.DateTime start_time { get; private set; }
    public GLib.DateTime? end_time { get; private set; }
    public bool is_allday { get; private set; default = false; }

    private static Services.TimeManager time_manager;
    private static Gtk.CssProvider css_provider;

    private Gtk.Grid grid;
    private Gtk.Image event_image;
    private Gtk.Label time_label;

    public EventRow (GLib.DateTime date, ICal.Component component, E.Source source) {
        Object (
            component: component,
            date: date,
            cal: (E.SourceCalendar?) source.get_extension (E.SOURCE_EXTENSION_CALENDAR)
        );
    }

    static construct {
        css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/elementary/desktop/wingpanel/datetime/EventRow.css");

        time_manager = Services.TimeManager.get_default ();
    }

    construct {
        var dt_start = component.get_dtstart ();
        if (dt_start.is_date ()) {
            // Don't convert timezone for date with only day info, leave it at midnight UTC
            start_time = Util.ical_to_date_time (dt_start);
        } else {
            start_time = Util.ical_to_date_time (dt_start).to_local ();
        }

        var dt_end = component.get_dtend ();
        if (dt_end.is_date ()) {
            // Don't convert timezone for date with only day info, leave it at midnight UTC
            end_time = Util.ical_to_date_time (dt_end);
        } else {
            end_time = Util.ical_to_date_time (dt_end).to_local ();
        }

        if (end_time != null && Util.is_the_all_day (start_time, end_time)) {
            is_allday = true;
        }

        unowned string icon_name = "office-calendar-symbolic";
        if (end_time == null) {
            icon_name = "alarm-symbolic";
        }

        event_image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.MENU);
        event_image.valign = Gtk.Align.START;

        unowned Gtk.StyleContext event_image_context = event_image.get_style_context ();
        event_image_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var name_label = new Gtk.Label (component.get_summary ());
        name_label.hexpand = true;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.lines = 3;
        name_label.max_width_chars = 30;
        name_label.wrap = true;
        name_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        name_label.xalign = 0;

        unowned Gtk.StyleContext name_label_context = name_label.get_style_context ();
        name_label_context.add_class ("title");
        name_label_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        time_label = new Gtk.Label (null);
        time_label.use_markup = true;
        time_label.xalign = 0;
        time_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.margin = 3;
        grid.margin_start = grid.margin_end = 6;
        grid.attach (event_image, 0, 0);
        grid.attach (name_label, 1, 0);
        if (!is_allday) {
            grid.attach (time_label, 1, 1);
        }

        unowned Gtk.StyleContext grid_context = grid.get_style_context ();
        grid_context.add_class ("event");
        grid_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        add (grid);

        set_color ();
        cal.notify["color"].connect (set_color);

        update_timelabel ();
        time_manager.notify["is-12h"].connect (update_timelabel);
    }

    private void update_timelabel () {
        var time_format = Granite.DateTime.get_default_time_format (time_manager.is_12h);
        time_label.label = "<small>%s – %s</small>".printf (start_time.format (time_format), end_time.format (time_format));
    }

    private void set_color () {
        Util.set_event_calendar_color (cal, grid);
        Util.set_event_calendar_color (cal, event_image);
    }
}