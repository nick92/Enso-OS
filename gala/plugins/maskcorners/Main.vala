//
//  Copyright (C) 2015 Rory J Sanderson
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

namespace Gala.Plugins.MaskCorners
{
	public class Main : Gala.Plugin
	{
		Gala.WindowManager? wm = null;
		Screen screen;
		Settings settings;

		List<Actor>[] cornermasks;
		int corner_radius = 4;

		public override void initialize (Gala.WindowManager wm)
		{
			this.wm = wm;
			screen = wm.get_screen ();
			settings = Settings.get_default ();

			setup_cornermasks ();

			settings.changed.connect (resetup_cornermasks);
		}

		public override void destroy ()
		{
			destroy_cornermasks ();
		}

		void setup_cornermasks ()
		{
			if (!settings.enable)
				return;

			int n_monitors = screen.get_n_monitors ();
			cornermasks = new List<Actor>[n_monitors];
			corner_radius = settings.corner_radius;

			if (settings.only_on_primary) {
				add_cornermasks (screen.get_primary_monitor ());
			} else {
				for (int m = 0; m < n_monitors; m++)
					add_cornermasks (m);
			}

			if (settings.disable_on_fullscreen)
				screen.in_fullscreen_changed.connect (fullscreen_changed);

			screen.monitors_changed.connect (resetup_cornermasks);
		}

		void destroy_cornermasks ()
		{
			screen.monitors_changed.disconnect (resetup_cornermasks);
			screen.in_fullscreen_changed.disconnect (fullscreen_changed);

			foreach (unowned List<Actor> list in cornermasks) {
				foreach (Actor actor in list)
					actor.destroy ();
			}
		}

		void resetup_cornermasks ()
		{
			destroy_cornermasks ();
			setup_cornermasks ();
		}

		void fullscreen_changed ()
		{
			for (int i = 0; i < screen.get_n_monitors (); i++) {
				foreach (Actor actor in cornermasks[i]) {
					if (screen.get_monitor_in_fullscreen (i))
						actor.hide ();
					else
						actor.show ();
				}
	 		}
		}

		void add_cornermasks (int monitor_no)
		{
			var monitor_geometry = screen.get_monitor_geometry (monitor_no);

			Canvas canvas = new Canvas ();
			canvas.set_size (corner_radius, corner_radius);
			canvas.draw.connect (draw_cornermask);
			canvas.invalidate ();

			Actor actor = new Actor ();
			actor.set_content (canvas);
			actor.set_size (corner_radius, corner_radius);
			actor.set_position (monitor_geometry.x, monitor_geometry.y);
			actor.set_pivot_point ((float) 0.5, (float) 0.5);

			cornermasks[monitor_no].append (actor);
			wm.stage.add_child (actor);

			for (int p = 1; p < 4; p++) {
				Clone clone = new Clone (actor);
				clone.rotation_angle_z = p * 90;

				switch (p) {
					case 1:
						clone.set_position (monitor_geometry.x + monitor_geometry.width, monitor_geometry.y);
						break;
					case 2:
						clone.set_position (monitor_geometry.x + monitor_geometry.width, monitor_geometry.y + monitor_geometry.height);
						break;
					case 3:
						clone.set_position (monitor_geometry.x, monitor_geometry.y + monitor_geometry.height);
						break;
				}

				cornermasks[monitor_no].append (clone);
				wm.stage.add_child (clone);
			}
		}

		bool draw_cornermask (Cairo.Context context)
		{
			var buffer = new Granite.Drawing.BufferSurface (corner_radius, corner_radius);
			var buffer_context = buffer.context;

			buffer_context.arc (corner_radius, corner_radius, corner_radius, Math.PI, 1.5 * Math.PI);
			buffer_context.line_to (0, 0);
			buffer_context.line_to (0, corner_radius);
			buffer_context.set_source_rgb (0, 0, 0);
			buffer_context.fill ();

			context.set_operator (Cairo.Operator.CLEAR);
			context.paint ();
			context.set_operator (Cairo.Operator.OVER);
			context.set_source_surface (buffer.surface, 0, 0);
			context.paint ();

			return true;
		}
	}
}

public Gala.PluginInfo register_plugin ()
{
	return
	{
		"Mask Corners",
		"Gala Developers",
		typeof (Gala.Plugins.MaskCorners.Main),
		Gala.PluginFunction.ADDITION,
		Gala.LoadPriority.IMMEDIATE
	};
}

