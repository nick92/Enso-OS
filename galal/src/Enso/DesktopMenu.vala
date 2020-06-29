//
//  Copyright (C) 2014 Gala Developers
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
//  Authored By: Tom Beckmann
//

namespace Gala
{
	public class DesktopMenu : Gtk.Menu
	{

		Gtk.MenuItem change_background;
		Gtk.MenuItem random_background;
		Gtk.MenuItem show_desktop;
		Gtk.MenuItem workspace_view;
		WindowManager wm;

		public DesktopMenu (WindowManager _wm)
		{
			wm = _wm;
		}

		construct
		{
			show_desktop = new Gtk.MenuItem.with_label (_("Show Desktop"));
			show_desktop.activate.connect (() => {
				try {
					wm.perform_action (ActionType.MINIMIZE_ALL);
				} catch (Error e) {
					warning (e.message);
				}
			});
			append (show_desktop);

			workspace_view = new Gtk.MenuItem.with_label (_("Multitasking View"));
			workspace_view.activate.connect (() => {
				try {
					wm.perform_action (ActionType.SHOW_WORKSPACE_VIEW);
				} catch (Error e) {
					warning (e.message);
				}
			});
			append (workspace_view);

			append (new Gtk.SeparatorMenuItem ());

			random_background = new Gtk.MenuItem.with_label (_("Settings"));
			random_background.activate.connect (() => {
				try {
					Process.spawn_command_line_async (BehaviorSettings.get_default ().settings_action);
				} catch (Error e) {
					warning (e.message);
				}
			});
			append (random_background);

			change_background = new Gtk.MenuItem.with_label (_("Change Desktop Background"));
			change_background.activate.connect (() => {
				try {
					Process.spawn_command_line_async (BehaviorSettings.get_default ().change_background_action);
				} catch (Error e) {
					warning (e.message);
				}
			});
			append (change_background);

		}
	}
}
