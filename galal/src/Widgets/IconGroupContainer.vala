//
//  Copyright (C) 2014 Tom Beckmann
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

using Clutter;
using Meta;

namespace Gala
{
	/**
	 * This class contains the icon groups at the bottom and will take
	 * care of displaying actors for inserting windows between the groups
	 * once implemented
	 */
	public class IconGroupContainer : Actor
	{
		public const int SPACING = 48;
		public const int GROUP_WIDTH = 64;

		public signal void request_reposition ();

		public Screen screen { get; construct; }

		public IconGroupContainer (Screen screen)
		{
			Object (screen: screen);

			layout_manager = new BoxLayout ();
		}

		public void add_group (IconGroup group)
		{
			var index = group.workspace.index ();

			insert_child_at_index (group, index * 2);

			var thumb = new WorkspaceInsertThumb (index);
			thumb.notify["expanded"].connect_after (expanded_changed);
			insert_child_at_index (thumb, index * 2);

			update_inserter_indices ();
		}

		public void remove_group (IconGroup group)
		{
			var thumb = (WorkspaceInsertThumb) group.get_previous_sibling ();
			thumb.notify["expanded"].disconnect (expanded_changed);
			remove_child (thumb);

			remove_child (group);

			update_inserter_indices ();
		}

		void expanded_changed (ParamSpec param)
		{
			request_reposition ();
		}

		/**
		 * Calculates the width that will be occupied taking currently running animations
		 * end states into account
		 */
		public float calculate_total_width ()
		{
			var width = 0.0f;
			foreach (var child in get_children ()) {
				if (child is WorkspaceInsertThumb) {
					if (((WorkspaceInsertThumb) child).expanded)
						width += GROUP_WIDTH + SPACING * 2;
					else
						width += SPACING;
				} else
					width += GROUP_WIDTH;
			}

			width += SPACING;

			return width;
		}

		void update_inserter_indices ()
		{
			var current_index = 0;

			foreach (var child in get_children ()) {
				unowned WorkspaceInsertThumb thumb = child as WorkspaceInsertThumb;
				if (thumb != null) {
					thumb.workspace_index = current_index++;
				}
			}
		}
	}
}

