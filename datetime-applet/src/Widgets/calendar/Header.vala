// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2015 Maya Developers (http://launchpad.net/maya)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Maxwell Barvian
 *              Corentin Noël <corentin@elementaryos.org>
 */

namespace DateTime.Widgets {

/**
 * Represents the header at the top of the calendar grid.
 */
public class Header : Gtk.EventBox {
    private Gtk.Grid header_grid;
    private Gtk.Label[] labels;

    public bool draw_left_border = true;
    public Header () {
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;

        header_grid = new Gtk.Grid();
        header_grid.insert_column (7);
        header_grid.insert_row (1);
        header_grid.set_column_homogeneous (true);
        header_grid.set_row_homogeneous (true);
        header_grid.column_spacing = 0;
        header_grid.row_spacing = 0;
        header_grid.margin_bottom = 4;

        labels = new Gtk.Label[7];
        for (int c = 0; c < 7; c++) {
            labels[c] = new Gtk.Label ("");
            labels[c].hexpand = true;
            var label_grid = new Gtk.Grid ();
            label_grid.add (labels[c]);
            header_grid.attach (label_grid, c, 0, 1, 1);
        }

        add (header_grid);
    }

    public void update_columns (int week_starts_on) {
        var date = Util.strip_time(new GLib.DateTime.now_local ());
        date = date.add_days (week_starts_on - date.get_day_of_week ());
        foreach (var label in labels) {
            label.get_style_context ().add_class ("h4");
            label.label = date.format ("%a");
            date = date.add_days (1);
        }
    }
}

}
