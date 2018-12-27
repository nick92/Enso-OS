//
//  Copyright (C) 2017 Rico Tzschichholz
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

public static void docklet_init (Plank.DockletManager manager)
{
	manager.register_docklet (typeof (Docky.MultitaskingDocklet));
}

namespace Docky
{
	public class MultitaskingDocklet : Object, Plank.Docklet
	{
		public unowned string get_id ()
		{
			return "multitasking";
		}

		public unowned string get_name ()
		{
			return _("Multitasking");
		}

		public unowned string get_description ()
		{
			return "Display the Multitasking View.";
		}

		public unowned string get_icon ()
		{
			return "multitasking-view";
		}

		public bool is_supported ()
		{
			return true;
		}

		public Plank.DockElement make_element (string launcher, GLib.File file)
		{
			return new MultitaskingDockItem.with_dockitem_file (file);
		}
	}
}
