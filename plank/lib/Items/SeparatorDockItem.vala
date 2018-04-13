//
//  Copyright (C) 2015 Rico Tzschichholz
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

namespace Plank
{
	public class SeparatorDockItem : DockItem
	{
		static SeparatorDockItem? instance;

		public static unowned SeparatorDockItem get_instance ()
		{
			if (instance == null)
				instance = new SeparatorDockItem ();

			return instance;
		}

		construct
		{
			Icon = "resource://" + Plank.G_RESOURCE_PATH + "/img/separator.svg";
			Text = "Tony";
		}

		public SeparatorDockItem ()
		{

		}

		protected override AnimationType on_clicked (PopupButton button, Gdk.ModifierType mod, uint32 event_time)
		{
			return AnimationType.NONE;
		}

		/**
		 * {@inheritDoc}
		 */
		public override bool can_be_removed ()
		{
			return true;
		}

		/**
		 * {@inheritDoc}
		 */
		public override bool is_valid ()
		{
			return true;
		}
	}
}
