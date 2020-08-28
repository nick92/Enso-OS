/*-
 * Copyright (c) 2011–2018 elementary, Inc. (https://elementary.io)
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

public class DateTime.Widgets.CalendarView : Gtk.Grid {
    public signal void day_double_click ();
    public signal void event_updates ();
    public signal void selection_changed (GLib.DateTime? new_date);

    public GLib.DateTime? selected_date { get; private set; }

    private Grid grid;
    private Gtk.Stack stack;
    private Gtk.Grid big_grid;
    private Gtk.Button date_button;

    construct {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/org/enso/datetime/application.css");

        //  var label_style_context = label.get_style_context ();
        //  label_style_context.add_class ("header");
        //  label_style_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var left_button = new Gtk.Button.from_icon_name ("pan-start-symbolic");
        date_button = new Gtk.Button.with_label (new GLib.DateTime.now_local ().format (_("%OB, %Y")));
        date_button.tooltip_text = _("Go to today's date");
        var right_button = new Gtk.Button.from_icon_name ("pan-end-symbolic");

        var box_buttons = new Gtk.Grid ();
        box_buttons.hexpand = true;
        box_buttons.valign = Gtk.Align.CENTER;
        box_buttons.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        box_buttons.add (left_button);
        box_buttons.add (date_button);
        box_buttons.add (right_button);

        big_grid = create_big_grid ();

        stack = new Gtk.Stack ();
        stack.add (big_grid);
        stack.show_all ();
        stack.expand = true;

        stack.notify["transition-running"].connect (() => {
            if (stack.transition_running == false) {
                stack.get_children ().foreach ((child) => {
                    if (child != stack.visible_child) {
                        child.destroy ();
                    }
                });
            }
        });

        column_spacing = 6;
        row_spacing = 6;
        margin_start = margin_end = 10;
        //  attach (label, 0, 0);
        attach (box_buttons, 1, 0);
        attach (stack, 0, 1, 2);

        var model = CalendarModel.get_default ();
        model.notify["data-range"].connect (() => {
            date_button.label = model.month_start.format (_("%OB, %Y"));

            sync_with_model ();

            selected_date = null;
            selection_changed (selected_date);
        });

        left_button.clicked.connect (() => {
            model.change_month (-1);
        });

        right_button.clicked.connect (() => {
            model.change_month (1);
        });

        date_button.clicked.connect (() => {
            show_today ();
        });

        show_today ();
    }

    private Gtk.Grid create_big_grid () {
        grid = new DateTime.Widgets.Grid ();
        grid.show_all ();

        grid.on_event_add.connect ((date) => {
            show_date_in_maya (date);
            day_double_click ();
        });

        grid.selection_changed.connect ((date) => {
            selected_date = date;
            selection_changed (date);
        });

        return grid;
    }

    public void show_today () {
        var calmodel = CalendarModel.get_default ();
        var today = Util.strip_time (new GLib.DateTime.now_local ());
        var start = Util.get_start_of_month (today);
        selected_date = today;
        if (!start.equal (calmodel.month_start)) {
            calmodel.month_start = start;
        }
        sync_with_model ();

        grid.set_focus_to_today ();
    }

    // TODO: As far as maya supports it use the Dbus Activation feature to run the calendar-app.
    public void show_date_in_maya (GLib.DateTime date) {
        var command = "io.elementary.calendar --show-day %s".printf (date.format ("%F"));

        try {
            var appinfo = AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.NONE);
            appinfo.launch_uris (null, null);
        } catch (GLib.Error e) {
            //  var dialog = new Granite.MessageDialog.with_image_from_icon_name (
            //      _("Unable To Launch Calendar"),
            //      _("The program \"io.elementary.calendar\" may not be installed"),
            //      "dialog-error"
            //  );
            //  dialog.show_error_details (e.message);
            //  dialog.run ();
            //  dialog.destroy ();
        }
    }

    /* Sets the calendar widgets to the date range of the model */
    private void sync_with_model () {
        var model = CalendarModel.get_default ();
        if (grid.grid_range != null && (model.data_range.equals (grid.grid_range) || grid.grid_range.first_dt.compare (model.data_range.first_dt) == 0)) {
            grid.update_today ();
            return; // nothing else to do
        }

        GLib.DateTime previous_first = null;
        if (grid.grid_range != null)
            previous_first = grid.grid_range.first_dt;

        big_grid = create_big_grid ();
        stack.add (big_grid);

        grid.set_range (model.data_range, model.month_start);
        grid.update_weeks (model.data_range.first_dt, model.num_weeks);

        if (previous_first != null) {
            if (previous_first.compare (grid.grid_range.first_dt) == -1) {
                stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT;
            } else {
                stack.transition_type = Gtk.StackTransitionType.SLIDE_RIGHT;
            }
        }

        stack.set_visible_child (big_grid);
    }
}