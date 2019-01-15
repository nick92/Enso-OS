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

using Plank;

namespace Docky
{
	[DBus (name = "org.pantheon.gala")]
	interface GalaDBus : Object {
		public abstract void perform_action (int type) throws DBusError, IOError;
	}

	public class MultitaskingDockItem : DockletItem
	{
		/**
		 * {@inheritDoc}
		 */
		public MultitaskingDockItem.with_dockitem_file (GLib.File file)
		{
			GLib.Object (Prefs: new DockItemPreferences.with_file (file));
		}

		construct
		{
			Icon = "multitasking-view";
			Text = _("Multitasking View");
		}

		~MultitaskingDockItem ()
		{

		}

		protected override AnimationType on_scrolled (Gdk.ScrollDirection direction, Gdk.ModifierType mod, uint32 event_time)
		{
			return AnimationType.NONE;
		}

		protected override AnimationType on_clicked (PopupButton button, Gdk.ModifierType mod, uint32 event_time)
		{
			try {
				if (button == PopupButton.LEFT) {
					GalaDBus galaDBus = Bus.get_proxy_sync (BusType.SESSION, "org.pantheon.gala", "/org/pantheon/gala");
					
					galaDBus.perform_action(1);
					return AnimationType.LIGHTEN;
				}
			}catch(Error ex){
				error (ex.message);
			}
			return AnimationType.NONE;
		}
	}
}
