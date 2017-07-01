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
	/**
	 * Implement this interface on your {@link Plugin} class if you want to
	 * replace a component like the window overview or the multitasking view.
	 * It allows gala to hook up functionality like hotcorners and dbus
	 * invocation of your component.
	 */
	public interface ActivatableComponent : Object
	{
		/**
		 * The component was requested to be opened.
		 *
		 * @param hints The hashmap may contain special parameters that are useful
		 *              to the component. Currently, the only one implemented is the
		 *              'all-windows' hint to the windowoverview.
		 */
		public abstract void open (HashTable<string,Variant>? hints = null);

		/**
		 * The component was requested to be closed.
		 */
		public abstract void close ();

		/**
		 * Should return whether the component is currently opened. Used mainly for
		 * toggling by the window manager.
		 *
		 * @return Return true if the component is opened.
		 */
		public abstract bool is_opened ();
	}
}

