namespace Pantheon.Keyboard.Shortcuts
{
	// list of all shortcuts in gsettings, global object
	private List list;
	// class to interact with gsettings
	private Shortcuts.Settings settings;
	// array of tree views, one for each section
	private DisplayTree[] trees;

	private enum SectionID {
	    WINDOWS,
	    WORKSPACES,
	    SCREENSHOTS,
	    APPS,
	    MEDIA,
	    A11Y,
	    CUSTOM,
	    COUNT
	}

	private string[] section_names;

	// main class
	class Page : Pantheon.Keyboard.AbstractPage
	{
		public override void reset ()
		{
			for (int i = 0; i < SectionID.COUNT; i++) {
				var g = list.groups[i];

				for (int k = 0; k < g.actions.length; k++)
					settings.reset (g.schemas[k], g.keys[k]);
			}
			return;
		}

		public Page ()
		{
			CustomShortcutSettings.init ();

			// init public elements
			section_names = {
				_("Windows"),
				_("Workspaces"),
				_("Screenshots"),
				_("Applications"),
				_("Media"),
				_("Universal Access"),
				_("Custom")
			};

			list     = new List ();
			settings = new Shortcuts.Settings ();

			for (int id = 0; id < SectionID.CUSTOM; id++)
				trees += new Tree ((SectionID) id);

			if (CustomShortcutSettings.available)
				trees += new CustomTree ();

			// private elements
			var shortcut_display = new ShortcutDisplay (trees);
			var section_switcher = new SectionSwitcher ();

			this.attach (section_switcher, 0, 0, 1, 1);
			this.attach (shortcut_display, 1, 0, 2, 1);

			section_switcher.changed.connect (shortcut_display.change_selection);
		}
	}
}
