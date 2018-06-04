namespace Pantheon.Keyboard.Shortcuts {

    private class Tree : Gtk.TreeView, DisplayTree {

        public SectionID group { private get; construct; }

        private string[] actions;
        private Schema[] schemas;
        private string[] keys;

        public Tree (SectionID group) {
            Object (group: group);

            load_and_display_shortcuts ();

            var cell_desc = new Gtk.CellRendererText ();
            var cell_edit = new Gtk.CellRendererAccel ();

            cell_edit.editable   = true;
            cell_edit.accel_mode = Gtk.CellRendererAccelMode.OTHER;

            this.insert_column_with_attributes (-1, null, cell_desc, "text", 0);
            this.insert_column_with_attributes (-1, null, cell_edit, "text", 1);

            this.headers_visible = false;
            this.expand          = true;

            this.get_column (0).expand = true;

            this.button_press_event.connect ((event) => {
                if (event.window != this.get_bin_window ())
                    return false;

                Gtk.TreePath path;

                if (this.get_path_at_pos ((int) event.x, (int) event.y,
                                          out path, null, null, null)) {
                    Gtk.TreeViewColumn col = this.get_column (1);
                    this.grab_focus ();
                    this.set_cursor (path, col, true);
                }

                return true;
            });

            cell_edit.accel_edited.connect ((path, key, mods) =>  {
                var shortcut = new Shortcut (key, mods);
                change_shortcut (path, shortcut);
            });

            cell_edit.accel_cleared.connect ((path) => {
                change_shortcut (path, (Shortcut) null);
            });
        }

        void load_and_display_shortcuts () {
            list.get_group (group, out actions, out schemas, out keys);

            var store = new Gtk.ListStore (4, typeof (string), typeof (string),
                                              typeof (Schema), typeof (string));

            Gtk.TreeIter iter;

            for (int i = 0; i < actions.length; i++) {
                var shortcut = settings.get_val(schemas[i], keys[i]);

                if (shortcut == null)
                    continue;

                store.append (out iter);
                store.set (iter, 0, actions[i],
                                 1, shortcut.to_readable(),
                                 2, schemas[i],    // hidden
                                 3, keys[i], -1);  // hidden
            }

            model = store;
        }

        public bool shortcut_conflicts (Shortcut shortcut, out string name) {
            string[] actions, keys;
            Schema[] schemas;

            name = "";

            list.get_group (group, out actions, out schemas, out keys);

            for (int i = 0; i < actions.length; i++) {
                if (shortcut.is_equal (settings.get_val (schemas[i], keys[i]))) {
                    name = actions[i];
                    return true;
                }
            }

            return false;
        }

        public void reset_shortcut (Shortcut shortcut) {
            string[] actions, keys;
            Schema[] schemas;
            var empty_shortcut = new Shortcut ();

            list.get_group (group, out actions, out schemas, out keys);

            for (int i = 0; i < actions.length; i++)
                if (shortcut.is_equal (settings.get_val (schemas[i], keys[i])))
                    settings.set_val (schemas[i], keys[i], empty_shortcut);

            load_and_display_shortcuts ();
        }

        public bool change_shortcut (string path, Shortcut? shortcut) {
            Gtk.TreeIter  iter;
            GLib.Value    key, schema, name;

            model.get_iter (out iter, new Gtk.TreePath.from_string (path));

            model.get_value (iter, 0, out name);
            model.get_value (iter, 2, out schema);
            model.get_value (iter, 3, out key);

            string conflict_name;

            if (shortcut != null) {
                foreach (var tree in trees) {
                    if (tree.shortcut_conflicts (shortcut, out conflict_name) == false || conflict_name == (string) name) {
                        continue;
                    }

                    var dialog = new ConflictDialog (shortcut.to_readable (), conflict_name, (string) name);
                    dialog.reassign.connect (() => {
                        tree.reset_shortcut (shortcut);
                        settings.set_val ((Schema) schema, (string) key, shortcut);
                        load_and_display_shortcuts ();
                    });
                    dialog.transient_for = (Gtk.Window) this.get_toplevel ();
                    dialog.present ();
                    return false;
                }
            }

            warning((string) key);

            settings.set_val ((Schema) schema, (string) key, shortcut ?? new Shortcut ());
            load_and_display_shortcuts ();
            return true;
        }
    }
}
