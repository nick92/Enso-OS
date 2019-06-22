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
	public enum ActionType
	{
		NONE = 0,
		SHOW_WORKSPACE_VIEW,
		MAXIMIZE_CURRENT,
		MINIMIZE_CURRENT,
		MINIMIZE_ALL,
		OPEN_LAUNCHER,
		CUSTOM_COMMAND,
		WINDOW_OVERVIEW,
		WINDOW_OVERVIEW_ALL,
		FOCUS_CURRENT
	}


	/**
	 * Function that should return true if the given shortcut should be blocked.
	 */
	public delegate bool KeybindingFilter (Meta.KeyBinding binding);

	/**
	 * A minimal class mostly used to identify your call to {@link WindowManager.push_modal} and used
	 * to end your modal mode again with {@link WindowManager.pop_modal}
	 */
	public class ModalProxy : Object
	{
		/**
		 * A function which is called whenever a keybinding is pressed. If you supply a custom
		 * one you can filter out those that'd you like to be passed through and block all others.
		 * Defaults to blocking all.
		 * @see KeybindingFilter
		 */
		public KeybindingFilter? keybinding_filter { get; owned set; default = () => true; }

		public ModalProxy ()
		{
		}

		/**
		 * Small utility to allow all keybindings
		 */
		public void allow_all_keybindings ()
		{
			keybinding_filter = null;
		}
	}

	public interface WindowManager : Meta.Plugin
	{
		/**
		 * This is the container you'll most likely want to add your component to. It wraps
		 * every other container listed in this interface and is a direct child of the stage.
		 */
		public abstract Clutter.Actor ui_group { get; protected set; }

		/**
		 * The stage of the window manager
		 */
		public abstract Clutter.Stage stage { get; protected set; }

		/**
		 * A group containting all 'usual' windows
		 * @see top_window_group
		 */
		public abstract Clutter.Actor window_group { get; protected set; }

		/**
		 * The top window group contains special windows that are always placed on top
		 * like fullscreen windows.
		 */
		public abstract Clutter.Actor top_window_group { get; protected set; }

		/**
		 * The background group is a container for the background actors forming the wallpaper
		 */
		public abstract Meta.BackgroundGroup background_group { get; protected set; }

		/**
		 * Enters the modal mode, which means that all events are directed to the stage instead
		 * of the windows. This is the only way to receive keyboard events besides shortcut listeners.
		 *
		 * @return a {@link ModalProxy} which is needed to end the modal mode again and provides some
		 *         some basic control on the behavior of the window manager while it is in modal mode.
		 */
		public abstract ModalProxy push_modal ();

		/**
		 * May exit the modal mode again, unless another component has called {@link push_modal}
		 *
		 * @param proxy The {@link ModalProxy} received from {@link push_modal}
		 */
		public abstract void pop_modal (ModalProxy proxy);

		/**
		 * Returns whether the window manager is currently in modal mode.
		 * @see push_modal
		 */
		public abstract bool is_modal ();

		/**
		 * Tests if a given {@link ModalProxy} is valid and may be popped. Should not be necessary
		 * to use this function in most cases, but it may be helpful for debugging. Gala catches
		 * invalid proxies as well and emits a warning in that case.
		 *
		 * @param proxy The {@link ModalProxy} to check
		 * @return      Returns true if the prox is valid
		 */
		public abstract bool modal_proxy_valid (ModalProxy proxy);

		/**
		 * Tells the window manager to perform the given action.
		 *
		 * @param type The type of action to perform
		 */
		public abstract void perform_action (ActionType type);

		/**
		 * Moves the window to the workspace next to its current workspace in the given direction.
		 * Gala currently only supports LEFT and RIGHT.
		 *
		 * @param window    The window to be moved
		 * @param direction The direction in which to move the window
		 */
		public abstract void move_window (Meta.Window? window, Meta.MotionDirection direction);

		/**
		 * Switches to the next workspace in the given direction.
		 *
		 * @param direction The direction in which to switch
		 */
		public abstract void switch_to_next_workspace (Meta.MotionDirection direction);
	}
}

