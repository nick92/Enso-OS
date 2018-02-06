// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//
//  Copyright (C) 2011-2012 Giulio Collura
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

using Gtk;

namespace Panther {

    public enum Modality {
        NORMAL_VIEW = 0,
        CATEGORY_VIEW = 1,
        SEARCH_VIEW
    }

    public class Selector : Gtk.ButtonBox {

        public signal void mode_changed();

        private int _selected;
        public int selected {
            get {
                return this._selected;
            }
            set {
                this.set_selector(value);
            }
        }

        private Gtk.ToggleButton view_all;
        private Gtk.ToggleButton view_cats;

        public Selector(Gtk.Orientation orientation) {

            this._selected = -1;
            this.set_orientation(orientation);
            this.set_layout(Gtk.ButtonBoxStyle.START);

            view_all = new Gtk.ToggleButton();
            var image = new Gtk.Image.from_icon_name ("panther-icons-symbolic", Gtk.IconSize.MENU);
            image.tooltip_text = _("View as Grid");
            view_all.add(image);
            this.pack_start(view_all,false,false,0);

            view_cats = new Gtk.ToggleButton();
            image = new Gtk.Image.from_icon_name ("panther-categories-symbolic", Gtk.IconSize.MENU);
            image.tooltip_text = _("View by Category");
            view_cats.add(image);
            this.pack_start (view_cats,false,false,0);

            view_all.button_release_event.connect( (bt) => {
                this.set_selector(0);
                return true;
            });
            view_cats.button_release_event.connect( (bt) => {
                this.set_selector(1);
                return true;
            });
        }

        public int get_selector() {
            return this._selected;
        }

        public void set_selector(int v) {
            if (this._selected != v) {
                this._selected = v;
                switch(v) {
                case 0:
                    //this.view_all.set_active(true);
                    this.view_cats.set_active(false);
                    break;
                case 1:
                    //this.view_all.set_active(false);
                    this.view_cats.set_active(true);
                    break;
                }
                this.mode_changed();
            }
        }

    }

    public class PantherView : Gtk.Window {

        const string PANTHER_STYLE_CSS = """
            .view2 {
                border: none;
                box-shadow: none;
                opacity: 0.5;
            }
        """;

        // Widgets
        public Gtk.SearchEntry search_entry;
        public Gtk.Stack stack;
        public Selector view_selector;
        private Gtk.Revealer view_selector_revealer;

        // Views
        private Widgets.Grid grid_view;
        private Widgets.SearchView search_view;
        private Widgets.CategoryView category_view;

        public Gtk.Grid top;
        public Gtk.Grid container;
        public Gtk.Frame fcontainer;
        public Gtk.Stack main_stack;
        public Gtk.Box content_area;
        private Gtk.EventBox event_box;

        public Backend.AppSystem app_system;
        private Gee.ArrayList<GMenu.TreeDirectory> categories;
        public Gee.HashMap<string, Gee.ArrayList<Backend.App>> apps;
        public Gee.ArrayList<Backend.App> saved_apps;
        public SList<Backend.App> app_name;

        private Modality modality;
        private bool can_trigger_hotcorner = true;

        private Backend.SynapseSearch synapse;

        private bool saved_cat = false;

        // Sizes
        public int columns {
            get {
                return grid_view.get_page_columns ();
            }
        }
        public int rows {
            get {
                return grid_view.get_page_rows ();
            }
        }

        private int default_columns;
        private int default_rows;

        private int column_focus = 0;
        private int row_focus = 0;

        private int category_column_focus = 0;
        private int category_row_focus = 0;

        private int primary_monitor = 0;
        private bool avoid_show;

        public PantherView () {
            primary_monitor = screen.get_primary_monitor ();
            Gdk.Rectangle geometry;
            screen.get_monitor_geometry (primary_monitor, out geometry);
            if (Panther.settings.rows_int == 0) {
                Panther.settings.rows = (geometry.height * 5 / 9) / Pixels.ITEM_SIZE;
            } else {
                Panther.settings.rows = Panther.settings.rows_int;
            }

            if (Panther.settings.columns_int == 0) {
                Panther.settings.columns = (geometry.width * 2 / 5) / Pixels.ITEM_SIZE;
            } else {
                Panther.settings.columns = Panther.settings.columns_int;
            }

            var provider = new Gtk.CssProvider ();
            try {
                provider.load_from_data (PANTHER_STYLE_CSS, PANTHER_STYLE_CSS.length);
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (Error e) {
                critical (e.message);
            }

            // Window properties
            this.title = "Panther";
            this.skip_pager_hint = true;
            this.skip_taskbar_hint = true;
            this.set_keep_above (true);
            this.set_type_hint (Gdk.WindowTypeHint.MENU);
            this.focus_on_map = true;
            this.decorated = false;
            this.avoid_show = false;

            //get_style_context ().add_class ("view2");

            // Have the window in the right place
            read_settings (true);

            Panther.icon_theme = Gtk.IconTheme.get_default ();

            app_system = new Backend.AppSystem ();
            synapse = new Backend.SynapseSearch ();

            categories = app_system.get_categories ();
            apps = app_system.get_apps ();
            app_name = app_system.get_apps_by_name ();
            saved_apps = app_system.get_saved_apps ();

            if (Panther.settings.screen_resolution != @"$(geometry.width)x$(geometry.height)") {
                setup_size ();
            }

            //height_request = calculate_grid_height () + Pixels.BOTTOM_SPACE;
            setup_ui ();

            connect_signals ();
            debug ("Apps loaded");
        }

        public int calculate_grid_height () {
            return (int) (default_rows * Pixels.ITEM_SIZE +
                         (default_rows - 1) * Pixels.ROW_SPACING);
        }

        public int calculate_grid_width () {
            return (int) default_columns * Pixels.ITEM_SIZE + 24;
        }

        private void setup_size () {
            debug ("In setup_size ()");
            primary_monitor = screen.get_primary_monitor ();
            Gdk.Rectangle geometry;
            screen.get_monitor_geometry (primary_monitor, out geometry);
            Panther.settings.screen_resolution = @"$(geometry.width)x$(geometry.height)";
            //default_columns = 6;
            //default_rows = 5;
            while ((calculate_grid_width () >= 2 * geometry.width / 3)) {
                default_columns--;
            }

            while ((calculate_grid_height () >= 2 * geometry.height / 3)) {
                default_rows--;
            }

            if (Panther.settings.columns != default_columns) {
                Panther.settings.columns = default_columns;
            }
            if (Panther.settings.rows != default_rows)
                Panther.settings.rows = default_rows;
        }

        private void setup_ui () {
            debug ("In setup_ui ()");

            var provider = new Gtk.CssProvider ();
            try {
                provider.load_from_data (PANTHER_STYLE_CSS, PANTHER_STYLE_CSS.length);
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (Error e) {
                critical (e.message);
            }

            // Create the base container
            container = new Gtk.Grid ();
            container.row_spacing = 12;
            container.row_homogeneous = false;
            container.column_homogeneous = false;
            container.margin_top = 12;

            // Add top bar
            top = new Gtk.Grid ();
            top.orientation = Gtk.Orientation.HORIZONTAL;
            top.margin_start = 6;
            top.margin_end = 6;

            view_selector = new Selector(Gtk.Orientation.HORIZONTAL);
            view_selector.margin_end = 6;
            view_selector.margin_start = 6;
            view_selector_revealer = new Gtk.Revealer ();
            view_selector_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
            view_selector_revealer.add (view_selector);

            if (Panther.settings.use_category)
                this.view_selector.selected = 1;
            else
                this.view_selector.selected = 0;

            search_entry = new Gtk.SearchEntry ();
            search_entry.placeholder_text = _("Search Apps");
            search_entry.hexpand = true;
            search_entry.margin_start = 6;
            search_entry.margin_end = 6;

            if (Panther.settings.show_category_filter) {
                //top.add (view_selector_revealer);
            }
            top.add (search_entry);

            stack = new Gtk.Stack ();
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

            // Create the "NORMAL_VIEW"
            grid_view = new Widgets.Grid (Panther.settings.rows, Panther.settings.columns);
            stack.add_named (grid_view, "normal");

            // Create the "CATEGORY_VIEW"
            category_view = new Widgets.CategoryView (this);
            stack.add_named (category_view, "category");

            // Create the "SEARCH_VIEW"
            search_view = new Widgets.SearchView (this);
            search_view.margin_end = 6;
            search_view.start_search.connect ((match, target) => {
                search.begin (search_entry.text, match, target);
            });

            stack.add_named (search_view, "search");

            container.attach (top, 0, 0, 1, 1);
            container.attach (stack, 0, 1, 1, 1);

            this.fcontainer = new Gtk.Frame(null);
            this.fcontainer.add (container);

            event_box = new Gtk.EventBox ();
            event_box.add (fcontainer);

            this.add (event_box);

            if (Panther.settings.use_category)
                set_modality (Modality.CATEGORY_VIEW);
            else
                set_modality (Modality.NORMAL_VIEW);
            debug ("Ui setup completed");
        }


        public void grab_device () {
            var display = Gdk.Display.get_default ();
            var pointer = display.get_device_manager ().get_client_pointer ();
            var keyboard = pointer.associated_device;
            var keyboard_status = Gdk.GrabStatus.SUCCESS;

            if (keyboard != null && keyboard.input_source == Gdk.InputSource.KEYBOARD) {
                keyboard_status = keyboard.grab (get_window (), Gdk.GrabOwnership.NONE, true,
                                                 Gdk.EventMask.KEY_PRESS_MASK | Gdk.EventMask.KEY_RELEASE_MASK,
                                                 null, Gdk.CURRENT_TIME);
            }

            var pointer_status = pointer.grab (get_window (), Gdk.GrabOwnership.NONE, true,
                                               Gdk.EventMask.SMOOTH_SCROLL_MASK | Gdk.EventMask.BUTTON_PRESS_MASK |
                                               Gdk.EventMask.BUTTON_RELEASE_MASK | Gdk.EventMask.POINTER_MOTION_MASK,
                                               null, Gdk.CURRENT_TIME);

            if (pointer_status != Gdk.GrabStatus.SUCCESS || keyboard_status != Gdk.GrabStatus.SUCCESS)  {
                // If grab failed, retry again. Happens when "Applications" button is long held.
                Timeout.add (100, () => {
                    if (visible)
                        grab_device ();

                    return false;
                });
            }
        }

        public override bool button_press_event (Gdk.EventButton event) {
            var pointer = Gdk.Display.get_default ().get_device_manager ().get_client_pointer ();

            // get_window_at_position returns null if the window belongs to another application.
            if (pointer.get_window_at_position (null, null) == null) {
                hide ();
                return true;
            }

            return false;
        }

        public override void get_preferred_width (out int minimum_width, out int natural_width) {
            event_box.get_preferred_width (out minimum_width, out natural_width);
        }

        public override void get_preferred_height (out int minimum_height, out int natural_height) {
            event_box.get_preferred_height (out minimum_height, out natural_height);
        }

        public override bool map_event (Gdk.EventAny event) {
            if (visible)
                grab_device ();

            return false;
        }

        public bool reset_avoid_show() {
            this.avoid_show = false;
            return false;
        }

        public bool cat_saved {
          get {
            return this.saved_cat;
          }
          set {
            this.saved_cat = value;
          }
        }

        public void add_saved (string app) {

          categories = app_system.get_categories ();
          apps = app_system.get_apps ();
          app_name = app_system.get_apps_by_name ();
          saved_apps = app_system.get_saved_apps ();
          category_view.setup_sidebar ();

          string app_name = app.substring(0, app.length - 8);
          var note = new GLib.Notification(_(app_name));

          if(saved_cat)
            note.set_body(_("Removed from saved"));
          else
            note.set_body(_("Added to saved"));

          GLib.Application.get_default ().send_notification(null, note);

        }
        private void connect_signals () {

            this.focus_in_event.connect (() => {
                search_entry.grab_focus ();
                return false;
            });

            this.hide.connect (() => {
                this.avoid_show = true;
                GLib.Timeout.add(300,this.reset_avoid_show);
            });

            event_box.key_press_event.connect (on_key_press);
            search_entry.key_press_event.connect (search_entry_key_press);
            // Showing a menu reverts the effect of the grab_device function.
            search_entry.populate_popup.connect ((menu) => {
                menu.hide.connect (() => {
                    grab_device ();
                });
            });
            search_entry.search_changed.connect (() => {
                if (modality != Modality.SEARCH_VIEW)
                    set_modality (Modality.SEARCH_VIEW);
                search.begin (search_entry.text);
            });
            search_entry.grab_focus ();
            search_entry.activate.connect (search_entry_activated);

            search_view.app_launched.connect (() => {
                hide ();
            });

            // This function must be after creating the page switcher
            populate_grid_view ();

            view_selector.mode_changed.connect (() => {

                set_modality ((Modality) view_selector.selected);
            });

            // Auto-update settings when changed
            Panther.settings.rows_changed.connect (() => {read_settings (false, false, true);});
            Panther.settings.columns_changed.connect (() => {read_settings (false, false, true);});

            // Auto-update applications grid
            app_system.changed.connect (() => {
                categories = app_system.get_categories ();
                apps = app_system.get_apps ();
                app_name = app_system.get_apps_by_name ();
                saved_apps = app_system.get_saved_apps ();

                populate_grid_view ();
                category_view.setup_sidebar ();
            });

            // position on the right monitor when settings changed
            screen.size_changed.connect (() => {
                Gdk.Rectangle geometry;
                screen.get_monitor_geometry (screen.get_primary_monitor (), out geometry);
                if (Panther.settings.screen_resolution != @"$(geometry.width)x$(geometry.height)") {
                    setup_size ();
                    setup_ui ();
                }
                reposition ();
            });
            screen.monitors_changed.connect (() => {
                reposition ();
            });

            get_style_context ().notify["direction"].connect (() => {
                reposition ();
            });

            can_trigger_hotcorner = false;
        }

        public void reposition () {
            debug("Repositioning");

            var workspace_area = this.get_screen().get_monitor_workarea(this.screen.get_primary_monitor());

            int new_y;
            if (Panther.settings.show_at_top) {
                new_y = workspace_area.y;
            } else {
                new_y = workspace_area.y + workspace_area.height - this.get_window().get_height();
            }

            if (get_style_context ().direction == Gtk.TextDirection.LTR) {
                this.move (workspace_area.x, new_y);
            } else {
                this.move (workspace_area.x + workspace_area.width - this.get_window ().get_width (), new_y);
            }
        }

        private void change_view_mode (string key) {
            switch (key) {
                case "1": // Normal view
                    view_selector.selected = 0;
                    break;
                default: // Category view
                    view_selector.selected = 1;
                    break;
            }
        }

        // Handle super+space when the user is typing in the search entry
        private bool search_entry_key_press (Gdk.EventKey event) {
            if ((event.keyval == Gdk.Key.space) && ((event.state & Gdk.ModifierType.SUPER_MASK) != 0)) {
                hide ();
                return true;
            }

            switch (event.keyval) {
                case Gdk.Key.Tab:
                    // context view is disabled until we get plugins that are actually
                    // useful with a context
                    // search_view.toggle_context (!search_view.in_context_view);
                    return true;
                break;
                case Gdk.Key.Escape:
                    if (search_entry.text.length > 0) {
                        search_entry.text = "";
                    } else {
                        hide ();
                    }
                break;
            }

            return false;
        }

        private void search_entry_activated () {
            if (modality == Modality.SEARCH_VIEW) {
                if (search_view.launch_selected ()) {
                    hide ();
                }
            } else {
                if (get_focus () as Widgets.AppEntry != null) // checking the selected widget is an AppEntry
                    ((Widgets.AppEntry) get_focus ()).launch_app ();
            }
        }

        /*
          Overriding the default handler results in infinite loop of error messages
          when an input method is in use (Gtk3 bug?).  Key press events are
          captured by an Event Box and passed to this function instead.

          Events not dealt with here are propagated to the search_entry by the
          usual mechanism.
        */
        public bool on_key_press (Gdk.EventKey event) {
            var key = Gdk.keyval_name (event.keyval).replace ("KP_", "");

            event.state &= (Gdk.ModifierType.SHIFT_MASK |
                            Gdk.ModifierType.MOD1_MASK |
                            Gdk.ModifierType.CONTROL_MASK);

            if ((event.state & Gdk.ModifierType.CONTROL_MASK) != 0 &&
                (key == "1" || key == "2")) {
                change_view_mode (key);
                return true;
            }

            switch (key) {
                case "F4":
                    if ((event.state & Gdk.ModifierType.MOD1_MASK) != 0) {
                        hide ();
                    }

                    break;

                case "Escape":
                    if (search_entry.text.length > 0) {
                        search_entry.text = "";
                    } else {
                        hide ();
                    }

                    return true;

                case "Enter": // "KP_Enter"
                case "Return":
                case "KP_Enter":
                    if (modality == Modality.SEARCH_VIEW) {
                        if (search_view.launch_selected ()) {
                            hide ();
                        }
                    } else {
                        if (get_focus () as Widgets.AppEntry != null) // checking the selected widget is an AppEntry
                            ((Widgets.AppEntry)get_focus ()).launch_app ();
                    }
                    return true;


                case "Alt_L":
                case "Alt_R":
                    break;

                case "0":
                case "1":
                case "2":
                case "3":
                case "4":
                case "5":
                case "6":
                case "7":
                case "8":
                case "9":
                    int page = int.parse (key);

                    if (event.state != Gdk.ModifierType.MOD1_MASK)
                        return false;

                    if (modality == Modality.NORMAL_VIEW) {
                        if (page < 0 || page == 9)
                            grid_view.go_to_last ();
                        else
                            grid_view.go_to_number (page);
                    } else if (modality == Modality.CATEGORY_VIEW) {
                        if (page < 0 || page == 9)
                            category_view.app_view.go_to_last ();
                        else
                            category_view.app_view.go_to_number (page);
                    } else {
                        return false;
                    }
                    search_entry.grab_focus ();
                    break;

                case "Tab":
                    if (modality == Modality.NORMAL_VIEW) {
                        view_selector.selected = 1;
                        var new_focus = category_view.app_view.get_child_at (category_column_focus, category_row_focus);
                        if (new_focus != null)
                            new_focus.grab_focus ();
                    } else if (modality == Modality.CATEGORY_VIEW) {
                        view_selector.selected = 0;
                        var new_focus = grid_view.get_child_at (column_focus, row_focus);
                        if (new_focus != null)
                            new_focus.grab_focus ();
                    }
                    break;

                case "Left":
                    if (modality != Modality.NORMAL_VIEW && modality != Modality.CATEGORY_VIEW)
                        return false;

                    if (get_style_context ().direction == Gtk.TextDirection.LTR) {
                        move_left (event);
                    } else {
                        move_right (event);
                    }

                    break;
                case "Right":
                    if (modality != Modality.NORMAL_VIEW && modality != Modality.CATEGORY_VIEW)
                        return false;

                    if (get_style_context ().direction == Gtk.TextDirection.LTR) {
                        move_right (event);
                    } else {
                        move_left (event);
                    }

                    break;
                case "Up":
                    if (modality == Modality.NORMAL_VIEW) {
                            normal_move_focus (0, -1);
                    } else if (modality == Modality.CATEGORY_VIEW) {
                        if (event.state == Gdk.ModifierType.SHIFT_MASK) { // Shift + Up
                            if (category_view.category_switcher.selected != 0) {
                                category_view.category_switcher.selected--;
                                top_left_focus ();
                            }
                        } else if (search_entry.has_focus) {
                            category_view.category_switcher.selected--;
                        } else {
                          category_move_focus (0, -1);
                        }
                    } else if (modality == Modality.SEARCH_VIEW) {
                        search_view.up ();
                    }
                    break;

                case "Down":
                    if (modality == Modality.NORMAL_VIEW) {
                            normal_move_focus (0, +1);
                    } else if (modality == Modality.CATEGORY_VIEW) {
                        if (event.state == Gdk.ModifierType.SHIFT_MASK) { // Shift + Down
                            category_view.category_switcher.selected++;
                            top_left_focus ();
                        } else if (search_entry.has_focus) {
                            category_view.category_switcher.selected++;
                        } else { // the user has already selected an AppEntry
                            category_move_focus (0, +1);
                        }
                    } else if (modality == Modality.SEARCH_VIEW) {
                        search_view.down ();
                    }
                    break;

                case "Page_Up":
                    if (modality == Modality.NORMAL_VIEW) {
                        grid_view.go_to_previous ();
                    } else if (modality == Modality.CATEGORY_VIEW) {
                        category_view.category_switcher.selected--;
                        top_left_focus ();
                    }
                    break;

                case "Page_Down":
                    if (modality == Modality.NORMAL_VIEW) {
                        grid_view.go_to_next ();
                    } else if (modality == Modality.CATEGORY_VIEW) {
                        category_view.category_switcher.selected++;
                        top_left_focus ();
                    }
                    break;

                case "BackSpace":
                    if (event.state == Gdk.ModifierType.SHIFT_MASK) { // Shift + Delete
                        search_entry.text = "";
                    } else if (search_entry.has_focus) {
                        return false;
                    } else {
                        search_entry.grab_focus ();
                        search_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, 0, false);
                        return false;
                    }
                    break;

                case "Home":
                    if (search_entry.text.length > 0) {
                        return false;
                    }

                    if (modality == Modality.NORMAL_VIEW) {
                        grid_view.go_to_number (1);
                    } else if (modality == Modality.CATEGORY_VIEW) {
                        category_view.category_switcher.selected = 0;
                        top_left_focus ();
                    }
                    break;

                case "End":
                    if (search_entry.text.length > 0) {
                        return false;
                    }

                    if (modality == Modality.NORMAL_VIEW) {
                        grid_view.go_to_last ();
                    } else if (modality == Modality.CATEGORY_VIEW) {
                        category_view.category_switcher.selected = category_view.category_switcher.cat_size - 1;
                        top_left_focus ();
                    }
                    break;

                case "v":
                case "V":
                    if ((event.state & (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK)) != 0) {
                        search_entry.paste_clipboard ();
                    }
                    break;

                default:
                    if (!search_entry.has_focus) {
                        search_entry.grab_focus ();
                        search_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, 0, false);
                        search_entry.key_press_event (event);
                    }
                    return false;

            }

            return true;

        }

        public override bool scroll_event (Gdk.EventScroll event) {
            switch (event.direction.to_string ()) {
                case "GDK_SCROLL_UP":
                case "GDK_SCROLL_LEFT":
                    if (modality == Modality.NORMAL_VIEW)
                        grid_view.go_to_previous ();
                    else if (modality == Modality.CATEGORY_VIEW)
                        category_view.app_view.go_to_previous ();
                    break;
                case "GDK_SCROLL_DOWN":
                case "GDK_SCROLL_RIGHT":
                    if (modality == Modality.NORMAL_VIEW)
                        grid_view.go_to_next ();
                    else if (modality == Modality.CATEGORY_VIEW)
                        category_view.app_view.go_to_next ();
                    break;

            }

            return false;
        }

        public void show_panther () {

            if (this.avoid_show) {
                return;
            }

            search_entry.text = "";

            reposition ();
            show_all ();
            //this.event_box.show_all();
            this.container.show_all();
            present ();

            set_focus (null);
            search_entry.grab_focus ();
            //This is needed in order to not animate if the previous view was the search view.
            view_selector_revealer.transition_type = Gtk.RevealerTransitionType.NONE;
            stack.transition_type = Gtk.StackTransitionType.NONE;
            set_modality ((Modality) view_selector.selected);
            view_selector_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        }

        /*
         * Moves the current view to the left (undependent of the TextDirection).
         */
        private void move_left (Gdk.EventKey event) {
            if (modality == Modality.NORMAL_VIEW) {
                if (event.state == Gdk.ModifierType.SHIFT_MASK) {// Shift + Left
                    grid_view.go_to_previous ();
                } else {
                    normal_move_focus (-1, 0);
                }
            } else if (modality == Modality.CATEGORY_VIEW) {
                if (event.state == Gdk.ModifierType.SHIFT_MASK) // Shift + Left
                    category_view.app_view.go_to_previous ();
                else if (!search_entry.has_focus) {//the user has already selected an AppEntry
                    category_move_focus (-1, 0);
                }
            }
        }

        /*
         * Moves the current view to the right (undependent of the TextDirection).
         */
        private void move_right (Gdk.EventKey event) {
            if (modality == Modality.NORMAL_VIEW) {
                if (event.state == Gdk.ModifierType.SHIFT_MASK) // Shift + Right
                    grid_view.go_to_next ();
                else
                    normal_move_focus (+1, 0);
            } else if (modality == Modality.CATEGORY_VIEW) {
                if (event.state == Gdk.ModifierType.SHIFT_MASK) // Shift + Right
                    category_view.app_view.go_to_next ();
                else if (search_entry.has_focus) // there's no AppEntry selected, the user is switching category
                    top_left_focus ();
                else //the user has already selected an AppEntry
                    category_move_focus (+1, 0);
            }
        }

        private void set_modality (Modality new_modality) {
            modality = new_modality;

            switch (modality) {
                case Modality.NORMAL_VIEW:

                    if (Panther.settings.use_category)
                        Panther.settings.use_category = false;
                    view_selector_revealer.set_reveal_child (true);
                    stack.set_visible_child_name ("normal");

                    search_entry.grab_focus ();
                    break;

                case Modality.CATEGORY_VIEW:

                    if (!Panther.settings.use_category)
                        Panther.settings.use_category = true;
                    view_selector_revealer.set_reveal_child (true);
                    stack.set_visible_child_name ("category");

                    search_entry.grab_focus ();
                    break;

                case Modality.SEARCH_VIEW:
                    view_selector_revealer.set_reveal_child (false);
                    stack.set_visible_child_name ("search");
                    break;

            }
        }

        private async void search (string text, Synapse.SearchMatch? search_match = null,
            Synapse.Match? target = null) {

            var stripped = text.strip ();

            if (stripped == "") {
                // this code was making problems when selecting the currently searched text
                // and immediately replacing it. In that case two async searches would be
                // started and both requested switching from and to search view, which would
                // result in a Gtk error and the first letter of the new search not being
                // picked up. If we add an idle and recheck that the entry is indeed still
                // empty before switching, this problem is gone.
                Idle.add (() => {
                    if (search_entry.text.strip () == "")
                        set_modality ((Modality) view_selector.selected);
                    return false;
                });
                return;
            }

            if (modality != Modality.SEARCH_VIEW)
                set_modality (Modality.SEARCH_VIEW);

            Gee.List<Synapse.Match> matches;

            if (search_match != null) {
                search_match.search_source = target;
                matches = yield synapse.search (text, search_match);
            } else {
                matches = yield synapse.search (text);
            }

            Idle.add (() => {
                search_view.set_results (matches, text);
                return false;
            });

        }

        public void populate_grid_view () {
            grid_view.clear ();
            foreach (Backend.App app in app_system.get_apps_by_name ()) {
                var app_entry = new Widgets.AppEntry (app);
                app_entry.app_launched.connect (() => {
                    hide ();
                });
                grid_view.append (app_entry);
                app_entry.show_all ();
            }

            stack.set_visible_child_name ("normal");
        }

        private void read_settings (bool first_start = false, bool check_columns = true, bool check_rows = true) {
            if (check_columns) {
                if (Panther.settings.columns > 3)
                    default_columns = Panther.settings.columns;
                else
                    default_columns = Panther.settings.columns = 4;
            }

            if (check_rows) {
                if (Panther.settings.rows > 1)
                    default_rows = Panther.settings.rows;
                else
                    default_rows = Panther.settings.rows = 2;
            }

            if (!first_start) {
                grid_view.resize (default_rows, default_columns);
                populate_grid_view ();
                //height_request = calculate_grid_height () + Pixels.BOTTOM_SPACE;

                category_view.app_view.resize (default_rows, default_columns);
                category_view.show_filtered_apps (category_view.category_ids.get (category_view.category_switcher.selected));
            }
        }

        private void normal_move_focus (int delta_column, int delta_row) {
            if (get_focus () as Widgets.AppEntry != null) { // we check if any AppEntry has focus. If it does, we move
                if (column_focus + delta_column < 0 || row_focus + delta_row < 0)
                    return;

                var new_focus = grid_view.get_child_at (column_focus + delta_column, row_focus + delta_row); // we check if the new widget exists
                if (new_focus == null) {
                    if (delta_column <= 0)
                        return;
                    else {
                        new_focus = grid_view.get_child_at (column_focus + delta_column, 0);
                        if (new_focus == null)
                            return;

                        row_focus = -delta_row; // so it's 0 at the end
                    }
                }

                column_focus += delta_column;
                row_focus += delta_row;
                if (delta_column > 0 && column_focus % grid_view.get_page_columns () == 0 ) //check if we need to change page
                    grid_view.go_to_next ();
                else if (delta_column < 0 && (column_focus + 1) % grid_view.get_page_columns () == 0) //check if we need to change page
                    grid_view.go_to_previous ();

                new_focus.grab_focus ();
            } else { // we move to the first app in the top left corner of the current page
                column_focus = (grid_view.get_current_page ()-1) * grid_view.get_page_columns ();
                if (column_focus >= 0)
                    grid_view.get_child_at (column_focus, 0).grab_focus ();
                row_focus = 0;
            }
        }

        private void category_move_focus (int delta_column, int delta_row) {
            var new_focus = category_view.app_view.get_child_at (category_column_focus + delta_column, category_row_focus + delta_row);
            if (new_focus == null) {
                if (delta_row < 0 && category_view.category_switcher.selected != 0) {
                    category_view.category_switcher.selected--;
                    top_left_focus ();
                    return;
                } else if (delta_row > 0 && category_view.category_switcher.selected != category_view.category_switcher.cat_size - 1) {
                    category_view.category_switcher.selected++;
                    top_left_focus ();
                    return;
                } else if (delta_column > 0 && (category_column_focus + delta_column) % category_view.app_view.get_page_columns () == 0
                          && category_view.app_view.get_current_page ()+ 1 != category_view.app_view.get_n_pages ()) {
                    category_view.app_view.go_to_next ();
                    top_left_focus ();
                    return;
                } else if (category_column_focus == 0 && delta_column < 0) {
                    search_entry.grab_focus ();
                    category_column_focus = 0;
                    category_row_focus = 0;
                    return;
                } else {
                    return;
                }
            }

            category_column_focus += delta_column;
            category_row_focus += delta_row;
            if (delta_column > 0 && category_column_focus % category_view.app_view.get_page_columns () == 0 ) { // check if we need to change page
                category_view.app_view.go_to_next ();
            } else if (delta_column < 0 && (category_column_focus + 1) % category_view.app_view.get_page_columns () == 0) {
                // check if we need to change page
                category_view.app_view.go_to_previous ();
            }

            new_focus.grab_focus ();
        }

        // this method moves focus to the first AppEntry in the top left corner of the current page. Works in CategoryView only
        private void top_left_focus () {
            // this is the first column of the current page
            int first_column = (grid_view.get_current_page ()-1) * category_view.app_view.get_page_columns ();
            category_view.app_view.get_child_at (first_column, 0).grab_focus ();
            category_column_focus = first_column;
            category_row_focus = 1;
        }

        public void reset_category_focus () {
            category_column_focus = 0;
            category_row_focus = 0;
        }
    }

}
