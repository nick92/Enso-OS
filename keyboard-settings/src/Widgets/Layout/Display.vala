/*
* Copyright (c) 2017 elementary, LLC. (https://elementary.io)
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
* Boston, MA 02110-1301 USA
*/

namespace Pantheon.Keyboard.LayoutPage {
    // widget to display/add/remove/move keyboard layouts
    class Display : Gtk.Frame {
        private LayoutSettings settings;
        private Gtk.TreeView tree;
        private Gtk.Button up_button;
        private Gtk.Button down_button;
        private Gtk.Button add_button;
        private Gtk.Button remove_button;

        /*
         * Set to true when the user has just clicked on the list to prevent
         * that settings.layouts.active_changed triggers update_cursor
         */
        private bool cursor_changing = false;

        public Display () {
            settings = LayoutSettings.get_instance ();

            var cell = new Gtk.CellRendererText ();
            cell.ellipsize_set = true;
            cell.ellipsize = Pango.EllipsizeMode.END;

            tree = new Gtk.TreeView ();
            tree.insert_column_with_attributes (-1, null, cell, "text", 0);
            tree.headers_visible = false;
            tree.expand = true;
            tree.tooltip_column = 0;

            var scroll = new Gtk.ScrolledWindow (null, null);
            scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
            scroll.expand = true;
            scroll.add (tree);

            add_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON);
            add_button.tooltip_text = _("Add…");

            remove_button = new Gtk.Button.from_icon_name ("list-remove-symbolic", Gtk.IconSize.BUTTON);
            remove_button.sensitive = false;
            remove_button.tooltip_text = _("Remove");

            up_button = new Gtk.Button.from_icon_name ("go-up-symbolic", Gtk.IconSize.BUTTON);
            up_button.sensitive = false;
            up_button.tooltip_text = _("Move up");

            down_button = new Gtk.Button.from_icon_name ("go-down-symbolic", Gtk.IconSize.BUTTON);
            down_button.sensitive = false;
            down_button.tooltip_text = _("Move down");

            var actionbar = new Gtk.ActionBar ();
            actionbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
            actionbar.add (add_button);
            actionbar.add (remove_button);
            actionbar.add (up_button);
            actionbar.add (down_button);

            var grid = new Gtk.Grid ();
            grid.attach (scroll, 0, 0, 1, 1);
            grid.attach (actionbar, 0, 1, 1, 1);

            add (grid);

            var pop = new AddLayoutPopover ();

            add_button.clicked.connect( () => {
                pop.set_relative_to (add_button);
                pop.show_all ();
                add_item (pop);
            });

            remove_button.clicked.connect( () => {
                remove_item ();
            });

            up_button.clicked.connect (() => {
                settings.layouts.move_active_layout_up ();
                rebuild_list ();
            });

            down_button.clicked.connect (() => {
                settings.layouts.move_active_layout_down ();
                rebuild_list ();
            });

            tree.cursor_changed.connect (() => {
                cursor_changing = true;
                int new_index = get_cursor_index ();
                if (new_index != -1) {
                    settings.layouts.active = new_index;
                }
                update_buttons ();

                cursor_changing = false;
            });

            settings.layouts.active_changed.connect (() => {
                if (cursor_changing)
                    return;
                update_cursor ();
            });

            rebuild_list ();
            update_cursor ();
        }

        public void reset_all () {
            settings.reset_all ();
            rebuild_list ();
        }

        void update_buttons () {
                int index = get_cursor_index ();

                // if empty list
                if (index == -1) {
                    up_button.sensitive = false;
                    down_button.sensitive = false;
                    remove_button.sensitive = false;
                } else {
                    up_button.sensitive = (index != 0);
                    down_button.sensitive = (index != settings.layouts.length - 1);
                    remove_button.sensitive = (settings.layouts.length > 0);
                }
        }

        /**
         * Returns the index of the selected layout in the UI.
         * In case the list contains no layouts, it returns -1.
         */
        int get_cursor_index () {
                Gtk.TreePath path;

                tree.get_cursor (out path, null);

                if (path == null)
                {
                    return -1;
                }

                return (path.get_indices ())[0];
        }

        void update_cursor () {
            Gtk.TreePath path = new Gtk.TreePath.from_indices (settings.layouts.active);
            tree.set_cursor (path, null, false);
        }

        Gtk.ListStore build_store () {
            Gtk.ListStore list_store = new Gtk.ListStore (2, typeof (string), typeof(string));
            Gtk.TreeIter iter;
            for (uint i = 0; i < settings.layouts.length; i++) {
                string item = settings.layouts.get_layout (i).name;
                list_store.append (out iter);
                list_store.set (iter, 0, handler.get_display_name (item));
                list_store.set (iter, 1, item);
            }

            return list_store;
        }

        void rebuild_list () {
            tree.model = build_store ();
            update_cursor ();
            update_buttons ();
        }

        void remove_item () {
            settings.layouts.remove_active_layout ();
            rebuild_list ();
        }

        void add_item (LayoutPage.AddLayoutPopover pop) {
            pop.layout_added.connect ((layout, variant) => {
                settings.layouts.add_layout (new Layout.XKB (layout, variant));
                rebuild_list ();
            });
        }
    }
}
