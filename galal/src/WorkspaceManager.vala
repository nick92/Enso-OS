//
//  Copyright (C) 2014 Tom Beckmann, Rico Tzschichholz
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
	public class WorkspaceManager : Object
	{
		public static void init (WindowManager wm)
			requires (instance == null)
		{
			instance = new WorkspaceManager (wm);
		}

		public static unowned WorkspaceManager get_default ()
			requires (instance != null)
		{
			return instance;
		}

		static WorkspaceManager? instance = null;

		public WindowManager wm { get; construct; }

		Gee.LinkedList<Workspace> workspaces_marked_removed;
		int remove_freeze_count = 0;

		WorkspaceManager (WindowManager wm)
		{
			Object (wm: wm);
		}

		construct
		{
			unowned Screen screen = wm.get_screen ();

			workspaces_marked_removed = new Gee.LinkedList<Workspace> ();

			if (Prefs.get_dynamic_workspaces ())
				screen.override_workspace_layout (ScreenCorner.TOPLEFT, false, 1, -1);

			for (var i = 0; i < screen.get_n_workspaces (); i++)
				workspace_added (screen, i);

			Prefs.add_listener (prefs_listener);

			screen.workspace_switched.connect_after (workspace_switched);
			screen.workspace_added.connect (workspace_added);
			screen.workspace_removed.connect_after (workspace_removed);
			screen.window_entered_monitor.connect (window_entered_monitor);
			screen.window_left_monitor.connect (window_left_monitor);

			// make sure the last workspace has no windows on it
			if (Prefs.get_dynamic_workspaces ()
				&& Utils.get_n_windows (screen.get_workspace_by_index (screen.get_n_workspaces () - 1)) > 0)
				append_workspace ();
		}

		~WorkspaceManager ()
		{
			unowned Screen screen = wm.get_screen ();

			Prefs.remove_listener (prefs_listener);

			screen.workspace_added.disconnect (workspace_added);
			screen.workspace_switched.disconnect (workspace_switched);
			screen.workspace_removed.disconnect (workspace_removed);
			screen.window_entered_monitor.disconnect (window_entered_monitor);
			screen.window_left_monitor.disconnect (window_left_monitor);
		}

		void workspace_added (Screen screen, int index)
		{
			var workspace = screen.get_workspace_by_index (index);
			if (workspace == null)
				return;

			workspace.window_added.connect (window_added);
			workspace.window_removed.connect (window_removed);
		}

		void workspace_removed (Screen screen, int index)
		{
			unowned List<Workspace> existing_workspaces = screen.get_workspaces ();

			var it = workspaces_marked_removed.iterator ();
			while (it.next ()) {
				if (existing_workspaces.index (it.@get ()) < 0)
					it.remove ();
			}
		}

		void workspace_switched (Screen screen, int from, int to, MotionDirection direction)
		{
			if (!Prefs.get_dynamic_workspaces ())
				return;

			// remove empty workspaces after we switched away from them unless it's the last one
			var prev_workspace = screen.get_workspace_by_index (from);
			if (Utils.get_n_windows (prev_workspace) < 1
				&& from != screen.get_n_workspaces () - 1) {
				remove_workspace (prev_workspace);
			}
		}

		void window_added (Workspace? workspace, Window window)
		{
			if (workspace == null || !Prefs.get_dynamic_workspaces ()
				|| window.on_all_workspaces)
				return;

			unowned Screen screen = workspace.get_screen ();

			if ((window.window_type == WindowType.NORMAL
				|| window.window_type == WindowType.DIALOG
				|| window.window_type == WindowType.MODAL_DIALOG)
				&& workspace.index () == screen.get_n_workspaces () - 1)
				append_workspace ();
		}

		void window_removed (Workspace? workspace, Window window)
		{
			if (workspace == null || !Prefs.get_dynamic_workspaces ())
				return;

			unowned Screen screen = workspace.get_screen ();

			if (window.window_type != WindowType.NORMAL
				&& window.window_type != WindowType.DIALOG
				&& window.window_type != WindowType.MODAL_DIALOG)
				return;

			var index = screen.get_workspaces ().index (workspace);
			// has already been removed
			if (index < 0)
				return;

			var is_active_workspace = workspace == screen.get_active_workspace ();

			// remove it right away if it was the active workspace and it's not the very last
			// or we are in modal-mode
			if ((!is_active_workspace || wm.is_modal ())
				&& remove_freeze_count < 1
				&& Utils.get_n_windows (workspace) < 1
				&& index != screen.get_n_workspaces () - 1) {
				remove_workspace (workspace);
			}
		}

		void window_entered_monitor (Screen screen, int monitor, Window window)
		{
			if (InternalUtils.workspaces_only_on_primary ()
				&& monitor == screen.get_primary_monitor ())
				window_added (window.get_workspace (), window);
		}

		void window_left_monitor (Screen screen, int monitor, Window window)
		{
			if (InternalUtils.workspaces_only_on_primary ()
				&& monitor == screen.get_primary_monitor ())
				window_removed (window.get_workspace (), window);
		}

		void prefs_listener (Meta.Preference pref)
		{
			unowned Screen screen = wm.get_screen ();

			if (pref == Preference.DYNAMIC_WORKSPACES && Prefs.get_dynamic_workspaces ()) {
				// if the last workspace has a window, we need to append a new workspace
				if (Utils.get_n_windows (screen.get_workspace_by_index (screen.get_n_workspaces () - 1)) > 0)
					append_workspace ();
			}
		}

		void append_workspace ()
		{
			unowned Screen screen = wm.get_screen ();

			screen.append_new_workspace (false, screen.get_display ().get_current_time ());
		}

		/**
		 * Make sure we switch to a different workspace and remove the given one
		 *
		 * @param workspace The workspace to remove
		 */
		void remove_workspace (Workspace workspace)
		{
			unowned Screen screen = workspace.get_screen ();

			var time = screen.get_display ().get_current_time ();

			if (workspace == screen.get_active_workspace ()) {
				Workspace? next = null;

				next = workspace.get_neighbor (MotionDirection.LEFT);
				// if it's the first one we may have another one to the right
				if (next == workspace || next == null)
					next = workspace.get_neighbor (MotionDirection.RIGHT);

				if (next != null)
					next.activate (time);
			}

			// workspace has already been removed
			if (workspace in workspaces_marked_removed) {
				return;
			}

			workspace.window_added.disconnect (window_added);
			workspace.window_removed.disconnect (window_removed);
			
			workspaces_marked_removed.add (workspace);

			screen.remove_workspace (workspace, time);
		}

		/**
		 * Temporarily disables removing workspaces when they are empty
		 */
		public void freeze_remove ()
		{
			remove_freeze_count++;
		}

		/**
		 * Undo the effect of freeze_remove()
		 */
		public void thaw_remove ()
		{
			remove_freeze_count--;

			assert (remove_freeze_count >= 0);
		}

		/**
		 * If workspaces are dynamic, checks if there are empty workspaces that should
		 * be removed. Particularily useful in conjunction with freeze/thaw_remove to
		 * cleanup after an operation that required stable workspace/window indices
		 */
		public void cleanup ()
		{
			if (!Prefs.get_dynamic_workspaces ())
				return;

			var screen = wm.get_screen ();
			var last_index = screen.get_n_workspaces () - 1;

			foreach (var workspace in screen.get_workspaces ()) {
				if (Utils.get_n_windows (workspace) < 1
					&& workspace.index () != last_index) {
					remove_workspace (workspace);
				}
			}
		}
	}
}

