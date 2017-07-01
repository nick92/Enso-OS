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

namespace Gala.Plugins.Notify
{
	public class Main : Gala.Plugin
	{
		Gala.WindowManager? wm = null;

		NotifyServer server;
		NotificationStack stack;

		public override void initialize (Gala.WindowManager wm)
		{
			this.wm = wm;
			var screen = wm.get_screen ();

			stack = new NotificationStack (wm.get_screen ());
			wm.ui_group.add_child (stack);
			track_actor (stack);

			stack.animations_changed.connect ((running) => {
				freeze_track = running;
			});

			server = new NotifyServer (stack);

			update_position ();
			screen.monitors_changed.connect (update_position);
			screen.workareas_changed.connect (update_position);

			Bus.own_name (BusType.SESSION, "org.freedesktop.Notifications", BusNameOwnerFlags.NONE,
				(connection) => {
					try {
						connection.register_object ("/org/freedesktop/Notifications", server);
					} catch (Error e) {
						warning ("Registring notification server failed: %s", e.message);
						destroy ();
					}
				},
				() => {},
				(con, name) => {
					warning ("Could not aquire bus %s", name);
					destroy ();
				});
		}

		void update_position ()
		{
			var screen = wm.get_screen ();
			var primary = screen.get_primary_monitor ();
			var area = screen.get_active_workspace ().get_work_area_for_monitor (primary);

			stack.x = area.x + area.width - stack.width;
			stack.y = area.y;
		}

		public override void destroy ()
		{
			if (wm == null)
				return;

			untrack_actor (stack);
			stack.destroy ();
		}
	}
}

public Gala.PluginInfo register_plugin ()
{
	return Gala.PluginInfo () {
		name = "Notify",
		author = "Gala Developers",
		plugin_type = typeof (Gala.Plugins.Notify.Main),
		provides = Gala.PluginFunction.ADDITION,
		load_priority = Gala.LoadPriority.IMMEDIATE
	};
}

