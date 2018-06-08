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

public class DateTime.Widgets.WeekLabels : Gtk.Revealer {

    private Gtk.Grid day_grid;
    private Gtk.Label[] labels;
    private int nr_of_weeks;

    public WeekLabels () {
        vexpand = true;

        day_grid = new Gtk.Grid ();
        set_nr_of_weeks (5);
        day_grid.insert_row (1);
        day_grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 1, 0, 1, 6);
        day_grid.column_spacing = 9;
        day_grid.show ();

        day_grid.get_style_context().add_class ("weeks");

        add (day_grid);
    }

    public void update (GLib.DateTime date, int nr_of_weeks) {

        update_nr_of_labels (nr_of_weeks);

        if (Services.SettingsManager.get_default ().show_weeks) {
            no_show_all = false;
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
            set_reveal_child (true);

            var next = date;
            // Find the beginning of the week which is apparently always a monday
            int days_to_add = (8 - next.get_day_of_week()) % 7;
            next = next.add_days(days_to_add);
            foreach (var label in labels) {
                label.get_style_context ().add_class ("h4");
                label.height_request = 30;
                label.label = next.get_week_of_year ().to_string();
                next = next.add_weeks (1);
            }
        } else {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
            set_reveal_child (false);
            no_show_all = true;
            hide ();
        }
    }

    public void set_nr_of_weeks (int new_number) {
        day_grid.insert_row (new_number);
        nr_of_weeks = new_number;
    }

    public int get_nr_of_weeks () {
        return nr_of_weeks;
    }

    void update_nr_of_labels (int nr_of_weeks) {
        // Destroy all the old ones

        if (labels != null)
            foreach (var label in labels)
                label.destroy ();

        // Create new labels
        labels = new Gtk.Label[nr_of_weeks];
        for (int c = 0; c < nr_of_weeks; c++) {
            labels[c] = new Gtk.Label ("");
            labels[c].valign = Gtk.Align.START;
            labels[c].width_chars = 2;
            labels[c].margin = 1;
            day_grid.attach (labels[c], 0, c, 1, 1);
            labels[c].show ();
        }
    }
}
