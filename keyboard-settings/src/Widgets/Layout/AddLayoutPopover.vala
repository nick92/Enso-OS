class Pantheon.Keyboard.LayoutPage.AddLayout : Gtk.Popover {
	public signal void layout_added (string language, string layout);

	public AddLayout()
	{
		// add some labels
		var label_language = new Gtk.Label (_("Language:"));
		var label_layout   = new Gtk.Label (_("Layout:"));

		label_language.halign = label_layout.halign = Gtk.Align.END;

		var lang_list   = create_list_store (handler.languages);

        var renderer = new Gtk.CellRendererText ();

		var language_box = new Gtk.ComboBox.with_model (lang_list);
		language_box.pack_start (renderer, true);
		language_box.add_attribute (renderer, "text", 1);
		language_box.active = 0;
        language_box.id_column = 0;

        var layout_list = create_list_store (handler.get_variants_for_language (language_box.active_id));

        var layout_box = new Gtk.ComboBox.with_model (layout_list);
        layout_box.id_column = 0;
		layout_box.pack_start (renderer, true);
		layout_box.add_attribute (renderer, "text", 1);
		layout_box.active = 0;

		language_box.changed.connect(() => {
			layout_box.model = create_list_store (handler.get_variants_for_language (language_box.active_id));
			layout_box.active = 0;
		});

		var button_add    = new Gtk.Button.with_label (_("Add Layout"));
		var button_cancel = new Gtk.Button.with_label (_("Cancel"));

        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.layout_style = Gtk.ButtonBoxStyle.END;
        button_box.margin_top = 12;
        button_box.spacing = 6;
        button_box.add (button_cancel);
        button_box.add (button_add);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.row_spacing = 12;
        grid.margin = 12;
        grid.attach (label_language, 0, 0, 1, 1);
        grid.attach (label_layout, 0, 1, 1, 1);
        grid.attach (language_box, 1, 0, 1, 1);
        grid.attach (layout_box, 1, 1, 1, 1);
        grid.attach (button_box, 0, 2, 2, 1);

        add (grid);

		button_cancel.clicked.connect (() => {
			this.hide ();
		} );

		button_add.clicked.connect (() => {
			this.hide ();
			layout_added (language_box.active_id, layout_box.active_id);
		} );
	}

	// creates a list store from a string vector
	Gtk.ListStore create_list_store (HashTable<string, string> values)
	{
		Gtk.ListStore list_store = new Gtk.ListStore (2, typeof (string), typeof (string));
		list_store.set_default_sort_func (compare_func);
		list_store.set_sort_column_id (Gtk.TREE_SORTABLE_DEFAULT_SORT_COLUMN_ID, Gtk.SortType.ASCENDING);

		values.foreach ((key, val) => {
			Gtk.TreeIter iter;
			list_store.append (out iter);
			list_store.set (iter, 0, key, 1, val);
		});

		return list_store;
	}

	int compare_func (Gtk.TreeModel model, Gtk.TreeIter a, Gtk.TreeIter b) {
		Value val_a;
		Value val_b;
		model.get_value (a, 1, out val_a);
		model.get_value (b, 1, out val_b);
		if (((string) val_a) == _("Default")) {
			return -1;
		}

		if (((string) val_b) == _("Default")) {
			return 1;
		}

		return ((string) val_a).collate ((string) val_b);
	}
}
