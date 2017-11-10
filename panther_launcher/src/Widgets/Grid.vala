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

namespace Panther.Widgets {

    struct Page {
        public uint rows;
        public uint columns;
        public int number;
    }

    public class Grid : Gtk.Box {

        public Widgets.Switcher page_switcher;

        private Gtk.Stack stack;
        private Gtk.Grid current_grid;
        private Gee.HashMap<int, Gtk.Grid> grids;

        private uint current_row = 0;
        private uint current_col = 0;

        private Page page;

        public Grid (int rows, int columns) {
            page.rows = rows;
            page.columns = columns;
            page.number = 1;
            var main_grid = new Gtk.Grid ();
            main_grid.orientation = Gtk.Orientation.VERTICAL;
            main_grid.row_spacing = 30;
            main_grid.margin_bottom = 12;
            stack = new Gtk.Stack ();
            stack.expand = false;
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            page_switcher = new Widgets.Switcher ();
            page_switcher.set_stack (stack);
            var fake_grid = new Gtk.Grid ();
            fake_grid.expand = true;

            main_grid.add (stack);
            main_grid.add (fake_grid);
            main_grid.add (page_switcher);
            add (main_grid);

            grids = new Gee.HashMap<int, Gtk.Grid> (null, null);
            create_new_grid ();
            go_to_number (1);
        }

        private void create_new_grid () {
            // Grid properties
            current_grid = new Gtk.Grid ();
            current_grid.expand = false;
            current_grid.row_homogeneous = false;
            current_grid.column_homogeneous = false;
            current_grid.margin_start = 12;
            current_grid.margin_end = 12;

            current_grid.row_spacing = Pixels.ROW_SPACING;
            current_grid.column_spacing = 0;
            grids.set (page.number, current_grid);
            stack.add_titled (current_grid, page.number.to_string (), page.number.to_string ());

            // Fake grids in case there are not enough apps to fill the grid
            current_grid.attach (new Gtk.Grid (), 0, 0, (int)page.columns, (int)page.rows);
        }

        public void append (Gtk.Widget widget) {
            update_position ();

            current_grid.attach (widget, (int)current_col, (int)current_row, 1, 1);
            current_col++;
            current_grid.show ();
        }

        private void update_position () {
            if (current_col == page.columns) {
                current_col = 0;
                current_row++;
            }

            if (current_row == page.rows) {
                page.number++;
                create_new_grid ();
                current_row = 0;
            }
        }

        public void clear () {
            foreach (Gtk.Grid grid in grids.values) {
                foreach (Gtk.Widget widget in grid.get_children ()) {
                    widget.destroy ();
                }

                grid.destroy ();
            }

            grids.clear ();
            current_row = 0;
            current_col = 0;
            page.number = 1;
            create_new_grid ();
            stack.set_visible_child (current_grid);
        }

        public Gtk.Widget? get_child_at (int column, int row) {
            var col = ((int)(column/page.columns))+1;

            var grid = grids.get (col);
            if (grid != null) {
                return grid.get_child_at (column - (int)page.columns*(col-1), row) as Widgets.AppEntry;
            } else {
                return null;
            }
        }

        public int get_page_columns () {
            return (int) page.columns;
        }

        public int get_page_rows () {
            return (int) page.rows;
        }

        public int get_n_pages () {
            return (int) page.number;
        }

        public int get_current_page () {
            return int.parse (stack.get_visible_child_name ());
        }

        public void go_to_next () {
            int page_number = get_current_page ()+1;
            if (page_number <= get_n_pages ())
                stack.set_visible_child_name (page_number.to_string ());

            page_switcher.update_selected ();
        }

        public void go_to_previous () {
            int page_number = get_current_page ()-1;
            if (page_number > 0)
                stack.set_visible_child_name (page_number.to_string ());

            page_switcher.update_selected ();
        }

        public void go_to_last () {
            stack.set_visible_child_name (get_n_pages ().to_string ());
            page_switcher.update_selected ();
        }

        public void go_to_number (int number) {
            stack.set_visible_child_name (number.to_string ());
            page_switcher.update_selected ();
        }

        public void resize (int rows, int columns) {
            clear ();
            page.rows = rows;
            page.columns = columns;
            page.number = 1;
        }
    }
}
