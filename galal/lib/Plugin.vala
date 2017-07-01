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

namespace Gala
{
	public enum PluginFunction
	{
		ADDITION,
		WINDOW_SWITCHER,
		DESKTOP,
		WORKSPACE_VIEW,
		WINDOW_OVERVIEW
	}

	public enum LoadPriority
	{
		/**
		 * Have your plugin loaded immediately once gala has started
		 */
		IMMEDIATE,
		/**
		 * Allow gala to defer loading your plugin once it got the
		 * major part of the initialization done
		 */
		DEFERRED
	}

	public struct PluginInfo
	{
		string name;
		string author;

		/**
		 * Type of your plugin class, has to be derived from the Plugin class.
		 */
		Type plugin_type;

		/**
		 * This property allows you to override default functionality of gala
		 * so systems won't be instantiated next to each other. Use
		 * PluginFunction.ADDITION if no special component is overridden.
		 */
		PluginFunction provides;

		/**
		 * Give gala a hint for when to load your plugin. Especially use DEFERRED
		 * if you're adding a completely new ui component that's not directly
		 * related to the wm.
		 */
		LoadPriority load_priority;

		/**
		 * You don't have to fill this field, it will be filled by gala with
		 * the filename in which your module was found.
		 */
		string module_name;
	}

	/**
	 * This class has to be implemented by every plugin.
	 * Additionally, the plugin module is required to have a register_plugin
	 * function which returns a PluginInfo struct.
	 * The plugin_type field has to be the type of your plugin class derived
	 * from this class.
	 */
	public abstract class Plugin : Object
	{
		/**
		 * Emitted when update_region is called. Mainly for internal purposes.
		 */
		public signal void region_changed ();

		/**
		 * The region indicates an area where mouse events should be sent to
		 * the stage, which means your actors, instead of the windows.
		 *
		 * It is calculated by the system whenever update_region is called.
		 * You can influce it with the custom_region and the track_actor function.
		 */
		public Meta.Rectangle[] region { get; private set; }

		/**
		 * This list will be merged with the region property. See region for
		 * more details. Changing this property will cause update_region to be
		 * called. Default to null.
		 */
		protected Meta.Rectangle[]? custom_region {
			get {
			   return _custom_region;
			}
			protected set {
				_custom_region = value;
				update_region ();
			}
		}

		/**
		 * Set this property to true while animating an actor if you have tracked
		 * actors to prevent constant recalculations of the regions during an
		 * animation.
		 */
		protected bool freeze_track {
			get {
				return _freeze_track;
			}
			set {
				_freeze_track = value;

				if (!_freeze_track)
					update_region ();
			}
		}

		private bool _freeze_track = false;
		private Meta.Rectangle[]? _custom_region = null;
		private List<Clutter.Actor> tracked_actors = new List<Clutter.Actor> ();

		/**
		 * Once this method is called you can start adding actors to the stage
		 * via the windowmanager instance that is given to you.
		 *
		 * @param wm The window manager.
		 */
		public abstract void initialize (WindowManager wm);

		/**
		 * This method is currently not called in the code, however you should
		 * still implement it to be compatible whenever we decide to use it.
		 * It should make sure that everything your plugin added to the stage
		 * is cleaned up.
		 */
		public abstract void destroy ();

		/**
		 * Listen to changes to the allocation of actor and update the region
		 * accordingly. You may add multiple actors, their shapes will be
		 * combined when one of them changes.
		 *
		 * @param actor The actor to be tracked
		 */
		public void track_actor (Clutter.Actor actor)
		{
			tracked_actors.prepend (actor);
			actor.allocation_changed.connect (actor_allocation_changed);

			update_region ();
		}

		/**
		 * Stop listening to allocation changes and remove the actor's
		 * allocation from the region array.
		 *
		 * @param actor The actor to stop listening the changes on
		 */
		public void untrack_actor (Clutter.Actor actor)
		{
			tracked_actors.remove (actor);
			actor.allocation_changed.disconnect (actor_allocation_changed);
		}

		/**
		 * You can call this method to force the system to update the region that
		 * is used by the window manager. It will automatically upon changes to
		 * the custom_region property and when a tracked actor's allocation changes
		 * unless freeze_track is set to true. You may need to call this function
		 * after setting freeze_track back to false after an animation to make the
		 * wm aware of the new position of the actor in question.
		 */
		public void update_region ()
		{
			var has_custom = custom_region != null;
			var len = tracked_actors.length () + (has_custom ? custom_region.length : 0);

			Meta.Rectangle[] regions = new Meta.Rectangle[len];
			var i = 0;

			if (has_custom) {
				for (var j = 0; j < custom_region.length; j++) {
					regions[i++] = custom_region[j];
				}
			}

			foreach (var actor in tracked_actors) {
				float x, y, w, h;
				actor.get_transformed_position (out x, out y);
				actor.get_transformed_size (out w, out h);

				if (w == 0 || h == 0)
					continue;

				regions[i++] = { (int) x, (int) y, (int) w, (int) h };
			}

			region = regions;

			region_changed ();
		}

		private void actor_allocation_changed (Clutter.ActorBox box, Clutter.AllocationFlags f)
		{
			if (!freeze_track)
				update_region ();
		}
	}
}

