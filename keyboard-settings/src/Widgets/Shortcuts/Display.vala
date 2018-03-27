// TODO use new Gtk.Stack widget here
namespace Pantheon.Keyboard.Shortcuts
{
	// creates a grid containing a tree view and an inline toolbar
	class ShortcutDisplay : Gtk.Grid
	{
		int selected;
		
		Gtk.ScrolledWindow scroll;
		DisplayTree[] trees;
		
		Gtk.Toolbar tbar;
		Gtk.ToolButton add_button;
		Gtk.ToolButton remove_button;
		
		public ShortcutDisplay (DisplayTree[] t)
		{
			selected = 0;
			
			foreach (var tree in t) {
				trees += tree;
			}
			
			scroll = new Gtk.ScrolledWindow (null, null);
			scroll.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
			scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
			scroll.shadow_type = Gtk.ShadowType.IN;
			scroll.expand = true;
			scroll.add (t[selected]);
	
			tbar = new Gtk.Toolbar ();
			tbar.set_style (Gtk.ToolbarStyle.ICONS);
			tbar.set_icon_size (Gtk.IconSize.SMALL_TOOLBAR);
			tbar.set_show_arrow (false);
			tbar.hexpand = true;
			tbar.no_show_all = true;
			
			scroll.get_style_context ().set_junction_sides(Gtk.JunctionSides.BOTTOM);
			tbar.get_style_context ().add_class(Gtk.STYLE_CLASS_INLINE_TOOLBAR);
			tbar.get_style_context ().set_junction_sides(Gtk.JunctionSides.TOP);

			add_button = new Gtk.ToolButton (null, _("Add"));
			remove_button = new Gtk.ToolButton (null, _("Remove"));
		
			add_button.set_tooltip_text    (_("Add"));
			remove_button.set_tooltip_text (_("Remove"));
			
			add_button.set_icon_name    ("list-add-symbolic");
			remove_button.set_icon_name ("list-remove-symbolic");

			tbar.insert (add_button,    -1);
			tbar.insert (remove_button, -1);

			this.attach (scroll, 0, 0, 1, 1);
			this.attach (tbar,   0, 1, 1, 1);

			add_button.clicked.connect (() => 
			    (trees[selected] as CustomTree).on_add_clicked ());
			remove_button.clicked.connect (() =>
			    (trees[selected] as CustomTree).on_remove_clicked ());

			remove_button.sensitive = false;
		}

		// replace old tree view with new one
		public bool change_selection (int new_selection)
		{
			scroll.remove (trees[selected]);
			scroll.add (trees[new_selection]);

			if (new_selection == SectionID.CUSTOM) {
				var custom_tree = trees[new_selection] as CustomTree;
				custom_tree.row_selected.connect (row_selected);
				custom_tree.row_unselected.connect (row_unselected);

				custom_tree.command_editing_started.connect (disable_add);
				custom_tree.command_editing_ended.connect (enable_add);
			}

			if (selected == SectionID.CUSTOM) {
				var custom_tree = trees[selected] as CustomTree;
				custom_tree.row_selected.disconnect (row_selected);
				custom_tree.row_unselected.disconnect (row_unselected);

				custom_tree.command_editing_started.disconnect (disable_add);
				custom_tree.command_editing_ended.disconnect (enable_add);

			}

			selected = new_selection;

			tbar.no_show_all = new_selection != SectionID.CUSTOM;
			tbar.visible = new_selection == SectionID.CUSTOM;

			show_all ();

			return true;
		}

		private void row_selected ()
		{
			remove_button.sensitive = true;
		}

		private void row_unselected ()
		{
			remove_button.sensitive = false;
		}

		private void disable_add ()
		{
			add_button.sensitive = false;
		}

		private void enable_add ()
		{
			add_button.sensitive = true;
		}
		
	}
}