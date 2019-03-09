//
//  Copyright (C) 2018 Faissal Bensefia
//
//  This file is part of Plank.
//
//  Plank is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Plank is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

public static void docklet_init (Plank.DockletManager manager)
{
	manager.register_docklet (typeof (Docky.SoundDocklet));
}

namespace Docky
{
	public class SoundDocklet : Object, Plank.Docklet
	{
		public unowned string get_id ()
		{
			return "Sound";
		}

		public unowned string get_name ()
		{
			return _("Sound");
		}

		public unowned string get_description ()
		{
			return _("Displays Sound information");
		}

		public unowned string get_icon ()
		{
			return "gnome-settings-sound";
		}

		public bool is_supported ()
		{
			return true;
		}

		public Plank.DockElement make_element (string launcher, GLib.File file)
		{
			return new SoundDockItem.with_dockitem_file (file);
		}
	}
}
