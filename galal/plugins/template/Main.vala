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

/*
  This is a template class showing some of the things that can be done
  with a gala plugin and how to do them.
*/

namespace Gala.Plugins.Template
{
	public class Main : Gala.Plugin
	{
		const int PADDING = 50;

		Gala.WindowManager? wm = null;
		Clutter.Actor red_box;

		// This function is called as soon as Gala has started and gives you
		// an instance of the GalaWindowManager class.
		public override void initialize (Gala.WindowManager wm)
		{
			// we will save the instance to our wm property so we can use it later again
			// especially helpful when you have larger plugins with more functions,
			// we won't need it here
			this.wm = wm;

			// for demonstration purposes we'll add a red quad to the stage which will
			// turn green when clicked
			red_box = new Clutter.Actor ();
			red_box.set_size (100, 100);
			red_box.background_color = { 255, 0, 0, 255 };
			red_box.reactive = true;
			red_box.button_press_event.connect (turn_green);

			// we want to place it in the lower right of the primary monitor with a bit
			// of padding. refer to vapi/libmutter.vapi in gala's source for something
			// remotely similar to a documentation
			var screen = wm.get_screen ();
			var rect = screen.get_monitor_geometry (screen.get_primary_monitor ());

			red_box.x = rect.x + rect.width - red_box.width - PADDING;
			red_box.y = rect.y + rect.height - red_box.height - PADDING;

			// to order Gala to deliver mouse events to our box instead of the underlying
			// windows, we need to mark the region where the quad is located.
			// The plugin class offers an utility function for this purpose, the track_actor
			// function. It will update the region with the allocation of the actor
			// whenever its allocation changes. Make sure to set freeze_track to
			// true while animating the actor to not make gala update the region
			// every single frame.
			// You can also handle the region manually by setting the custom_region
			// property. The tracked actors and custom regions will be merged by
			// the plugin.
			track_actor (red_box);

			// now we'll add our box into the ui_group. This is where all the shell
			// elements and also the windows and backgrouds are located.
			wm.ui_group.add_child (red_box);
		}

		bool turn_green (Clutter.ButtonEvent event)
		{
			red_box.background_color = { 0, 255, 0, 255 };
			return true;
		}

		// This function is actually not even called by Gala at the moment,
		// still it might be a good idea to implement it anyway to make sure
		// your plugin is compatible in case we'd add disabling specific plugins
		// in the future
		public override void destroy ()
		{
			// here you would destroy actors you added to the stage or remove
			// keybindings

			red_box.destroy ();
		}
	}
}

// this little function just tells Gala which class of those you may have in
// your plugin is the one you want to start with and delivers some additional
// details about your plugin. It also gives you the option to choose a specific
// function which your plugin fulfils. Gala will then make sure that there is
// no duplicate functionality.
public Gala.PluginInfo register_plugin ()
{
	return {
		"template-plugin",                    // the plugin's name
		"Tom Beckmann <tomjonabc@gmail.com>", // you, the author
		typeof (Gala.Plugins.Template.Main),  // the type of your plugin class

		Gala.PluginFunction.ADDITION,         // the function which your plugin
		                                      // fulfils, ADDITION means nothing
		                                      // specific

		Gala.LoadPriority.IMMEDIATE           // indicates whether your plugin's
		                                      // start can be delayed until gala
		                                      // has loaded the important stuff or
		                                      // if you want your plugin to start
		                                      // right away. False means wait.
	};
}

