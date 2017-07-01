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
	public class WorkspaceInsertThumb : Actor
	{
		public const int EXPAND_DELAY = 300;

		public int workspace_index { get; construct set; }
		public bool expanded { get; private set; default = false; }

		uint expand_timeout = 0;

		public WorkspaceInsertThumb (int workspace_index)
		{
			Object (workspace_index: workspace_index);

			width = IconGroupContainer.SPACING;
			height = IconGroupContainer.GROUP_WIDTH;
			y = (IconGroupContainer.GROUP_WIDTH - IconGroupContainer.SPACING) / 2;
			opacity = 0;
			set_pivot_point (0.5f, 0.5f);
			reactive = true;
			x_align = Clutter.ActorAlign.CENTER;

			var drop = new DragDropAction (DragDropActionType.DESTINATION, "multitaskingview-window");
			drop.crossed.connect ((hovered) => {
				if (!Prefs.get_dynamic_workspaces ())
					return;

				if (!hovered) {
					if (expand_timeout != 0) {
						Source.remove (expand_timeout);
						expand_timeout = 0;
					}

					transform (false);
				} else
					expand_timeout = Timeout.add (EXPAND_DELAY, expand);
			});

			add_action (drop);
		}

		public void set_window_thumb (Window window)
		{
			destroy_all_children ();

			var icon = new WindowIcon (window, IconGroupContainer.GROUP_WIDTH);
			icon.x_align = ActorAlign.CENTER;
			add_child (icon);
		}

		bool expand ()
		{
			expand_timeout = 0;

			transform (true);

			return false;
		}

		void transform (bool expand)
		{
			save_easing_state ();
			set_easing_mode (AnimationMode.EASE_OUT_QUAD);
			set_easing_duration (200);

			if (!expand) {
				remove_transition ("pulse");
				opacity = 0;
				width = IconGroupContainer.SPACING;
				expanded = false;
			} else {
				add_pulse_animation ();
				opacity = 200;
				width = IconGroupContainer.GROUP_WIDTH + IconGroupContainer.SPACING * 2;
				expanded = true;
			}

			restore_easing_state ();
		}

		void add_pulse_animation ()
		{
			var transition = new TransitionGroup ();
			transition.duration = 800;
			transition.auto_reverse = true;
			transition.repeat_count = -1;
			transition.progress_mode = AnimationMode.LINEAR;

			var scale_x_transition = new PropertyTransition ("scale-x");
			scale_x_transition.set_from_value (0.8);
			scale_x_transition.set_to_value (1.1);
			scale_x_transition.auto_reverse = true;

			var scale_y_transition = new PropertyTransition ("scale-y");
			scale_y_transition.set_from_value (0.8);
			scale_y_transition.set_to_value (1.1);
			scale_y_transition.auto_reverse = true;

			transition.add_transition (scale_x_transition);
			transition.add_transition (scale_y_transition);

			add_transition ("pulse", transition);
		}
	}
}

