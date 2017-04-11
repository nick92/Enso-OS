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

using Meta;

namespace Gala
{
	/**
	 * A clone for a MetaWindowActor that will guard against the
	 * meta_window_appears_focused crash by disabling painting the clone
	 * as soon as it gets unavailable.
	 */
	public class SafeWindowClone : Clutter.Clone
	{
		public Window window { get; construct; }

		/**
		 * If set to true, the SafeWindowClone will destroy itself when the connected
		 * window is unmanaged
		 */
		public bool destroy_on_unmanaged { get; construct set; default = false; }

		/**
		 * Creates a new SafeWindowClone
		 *
		 * @param window               The window to clone from
		 * @param destroy_on_unmanaged see destroy_on_unmanaged property
		 */
		public SafeWindowClone (Window window, bool destroy_on_unmanaged = false)
		{
			var actor = (WindowActor) window.get_compositor_private ();

			Object (window: window,
					source: actor,
					destroy_on_unmanaged: destroy_on_unmanaged);
		}

		construct
		{
			if (source != null)
				window.unmanaged.connect (reset_source);
		}

		~SafeWindowClone ()
		{
			window.unmanaged.disconnect (reset_source);
		}

		void reset_source ()
		{
			// actually destroying the clone will be handled somewhere else (unless we were
			// requested to destroy it), we just need to make sure the clone doesn't attempt
			// to draw a clone of a window that has been destroyed
			source = null;

			if (destroy_on_unmanaged)
				destroy ();
		}
	}
}

