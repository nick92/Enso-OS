namespace Pantheon.Keyboard.LayoutPage
{
    // widget to display/add/remove/move keyboard layouts
    class Display : Gtk.Grid
    {

        LayoutSettings settings;
        Gtk.TreeView tree;
        Gtk.ToolButton up_button;
        Gtk.ToolButton down_button;
        Gtk.ToolButton add_button;
        Gtk.ToolButton remove_button;

        /*
         * Set to true when the user has just clicked on the list to prevent
         * that settings.layouts.active_changed triggers update_cursor
         */
        bool cursor_changing = false;

        public Display ()
        {
            settings = LayoutSettings.get_instance ();

            tree     = new Gtk.TreeView ();
            var cell = new Gtk.CellRendererText ();
            cell.ellipsize_set = true;
            cell.ellipsize = Pango.EllipsizeMode.END;

            tree.insert_column_with_attributes (-1, null, cell, "text", 0);
            tree.headers_visible = false;
            tree.expand = true;
            tree.tooltip_column = 0;

            var scroll = new Gtk.ScrolledWindow(null, null);
            scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
            scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            scroll.shadow_type = Gtk.ShadowType.IN;
            scroll.add (tree);
            scroll.expand = true;

            var tbar = new Gtk.Toolbar();
            tbar.set_style(Gtk.ToolbarStyle.ICONS);
            tbar.set_icon_size(Gtk.IconSize.SMALL_TOOLBAR);
            tbar.set_show_arrow(false);
            tbar.hexpand = true;

            scroll.get_style_context().set_junction_sides(Gtk.JunctionSides.BOTTOM);
            tbar.get_style_context().add_class(Gtk.STYLE_CLASS_INLINE_TOOLBAR);
            tbar.get_style_context().set_junction_sides(Gtk.JunctionSides.TOP);

            add_button    = new Gtk.ToolButton (null, _("Add…"));
            remove_button = new Gtk.ToolButton (null, _("Remove"));
            up_button     = new Gtk.ToolButton (null, _("Move up"));
            down_button   = new Gtk.ToolButton (null, _("Move down"));

            add_button.set_tooltip_text    (_("Add…"));
            remove_button.set_tooltip_text (_("Remove"));
            up_button.set_tooltip_text     (_("Move up"));
            down_button.set_tooltip_text   (_("Move down"));

            add_button.set_icon_name    ("list-add-symbolic");
            remove_button.set_icon_name ("list-remove-symbolic");
            up_button.set_icon_name     ("go-up-symbolic");
            down_button.set_icon_name   ("go-down-symbolic");

            remove_button.sensitive = false;
            up_button.sensitive     = false;
            down_button.sensitive   = false;

            tbar.insert (add_button,    -1);
            tbar.insert (remove_button, -1);
            tbar.insert (up_button,     -1);
            tbar.insert (down_button,   -1);

            this.attach (scroll, 0, 0, 1, 1);
            this.attach (tbar,   0, 1, 1, 1);

            var pop = new AddLayout ();

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

        public void reset_all ()
        {
            settings.reset_all ();
            rebuild_list ();
        }

        void update_buttons () {
                int index = get_cursor_index ();

                // if empty list
                if (index == -1)
                {
                    up_button.sensitive     = false;
                    down_button.sensitive   = false;
                    remove_button.sensitive = false;
                } else {
                    up_button.sensitive     = (index != 0);
                    down_button.sensitive   = (index != settings.layouts.length - 1);
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

        void remove_item ()
        {
            settings.layouts.remove_active_layout ();
            rebuild_list ();
        }

        void add_item (LayoutPage.AddLayout pop)
        {
            pop.layout_added.connect ((layout, variant) => {
                settings.layouts.add_layout (new Layout.XKB (layout, variant));
                rebuild_list ();
            });
        }
    }
}
