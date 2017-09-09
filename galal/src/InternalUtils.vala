//
//  Copyright (C) 2012 Tom Beckmann, Rico Tzschichholz
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
	public enum InputArea
	{
		NONE,
		FULLSCREEN,
		DEFAULT
	}

	public class InternalUtils
	{
		public static bool workspaces_only_on_primary ()
		{
			return Prefs.get_dynamic_workspaces ()
				&& Prefs.get_workspaces_only_on_primary ();
		}

		/*
		 * Reload shadow settings
		 */
		public static void reload_shadow ()
		{
			var factory = ShadowFactory.get_default ();
			var settings = ShadowSettings.get_default ();
			Meta.ShadowParams shadow;

			//normal focused
			shadow = settings.get_shadowparams ("normal_focused");
			factory.set_params ("normal", true, shadow);

			//normal unfocused
			shadow = settings.get_shadowparams ("normal_unfocused");
			factory.set_params ("normal", false, shadow);

			//menus
			shadow = settings.get_shadowparams ("menu");
			factory.set_params ("menu", false, shadow);
			factory.set_params ("dropdown-menu", false, shadow);
			factory.set_params ("popup-menu", false, shadow);

			//dialog focused
			shadow = settings.get_shadowparams ("dialog_focused");
			factory.set_params ("dialog", true, shadow);
			factory.set_params ("modal_dialog", false, shadow);

			//dialog unfocused
			shadow = settings.get_shadowparams ("normal_unfocused");
			factory.set_params ("dialog", false, shadow);
			factory.set_params ("modal_dialog", false, shadow);
		}

		/**
		 * set the area where clutter can receive events
		 **/
		public static void set_input_area (Screen screen, InputArea area)
		{
			var display = screen.get_display ();

			X.Xrectangle[] rects = {};
			int width, height;
			screen.get_size (out width, out height);
			var geometry = screen.get_monitor_geometry (screen.get_primary_monitor ());

			switch (area) {
				case InputArea.FULLSCREEN:
					X.Xrectangle rect = {0, 0, (ushort)width, (ushort)height};
					rects = {rect};
					break;
				case InputArea.DEFAULT:
					var schema = BehaviorSettings.get_default ().schema;

					// if ActionType is NONE make it 0 sized
					ushort tl_size = (schema.get_enum ("hotcorner-topleft") != ActionType.NONE ? 1 : 0);
					ushort tr_size = (schema.get_enum ("hotcorner-topright") != ActionType.NONE ? 1 : 0);
					ushort bl_size = (schema.get_enum ("hotcorner-bottomleft") != ActionType.NONE ? 1 : 0);
					ushort br_size = (schema.get_enum ("hotcorner-bottomright") != ActionType.NONE ? 1 : 0);

					X.Xrectangle topleft = {(short)geometry.x, (short)geometry.y, tl_size, tl_size};
					X.Xrectangle topright = {(short)(geometry.x + geometry.width - 1), (short)geometry.y, tr_size, tr_size};
					X.Xrectangle bottomleft = {(short)geometry.x, (short)(geometry.y + geometry.height - 1), bl_size, bl_size};
					X.Xrectangle bottomright = {(short)(geometry.x + geometry.width - 1), (short)(geometry.y + geometry.height - 1), br_size, br_size};

					rects = {topleft, topright, bottomleft, bottomright};

					// add plugin's requested areas
					if (area == InputArea.FULLSCREEN || area == InputArea.DEFAULT) {
						foreach (var rect in PluginManager.get_default ().regions) {
							rects += rect;
						}
					}
					break;
				case InputArea.NONE:
				default:
					Util.empty_stage_input_region (screen);
					return;
			}

			var xregion = X.Fixes.create_region (display.get_xdisplay (), rects);
			Util.set_stage_input_region (screen, xregion);
		}

		public static string get_system_background_path ()
		{
			var filename = AppearanceSettings.get_default ().workspace_switcher_background;
			var default_file = Config.PKGDATADIR + "/texture.png";

			if (filename == "") {
				filename = default_file;
			} else if (!FileUtils.test (filename, FileTest.IS_REGULAR)) {
				warning ("Failed to load %s", filename);
				filename = default_file;
			}

			return filename;
		}

		/**
		 * Inserts a workspace at the given index. To ensure the workspace is not immediately
		 * removed again when in dynamic workspaces, the window is first placed on it.
		 *
		 * @param index  The index at which to insert the workspace
		 * @param new_window A window that should be moved to the new workspace
		 */
		public static void insert_workspace_with_window (int index, Window new_window)
		{
			unowned List<WindowActor> actors = Compositor.get_window_actors (new_window.get_screen ());

			var workspace_manager = WorkspaceManager.get_default ();
			workspace_manager.freeze_remove ();

			new_window.change_workspace_by_index (index, false);

			foreach (unowned Meta.WindowActor actor in actors) {
				unowned Meta.Window window = actor.get_meta_window ();
				if (actor.is_destroyed ())
					continue;

				var window_index = window.get_workspace ().index ();

				if (!window.on_all_workspaces
					&& window != new_window
					&& window_index >= index) {
					window.change_workspace_by_index (window_index + 1, true);
				}
			}

			workspace_manager.thaw_remove ();
			workspace_manager.cleanup ();
		}

		// Code ported from KWin present windows effect
		// https://projects.kde.org/projects/kde/kde-workspace/repository/revisions/master/entry/kwin/effects/presentwindows/presentwindows.cpp

		// constants, mainly for natural expo
		const int GAPS = 10;
		const int MAX_TRANSLATIONS = 100000;
		const int ACCURACY = 20;

		// some math utilities
		static int squared_distance (Gdk.Point a, Gdk.Point b)
		{
			var k1 = b.x - a.x;
			var k2 = b.y - a.y;

			return k1*k1 + k2*k2;
		}

		static bool rect_is_overlapping_any (Meta.Rectangle rect, Meta.Rectangle[] rects, Meta.Rectangle border)
		{
			if (!border.contains_rect (rect))
				return true;
			foreach (var comp in rects) {
				if (comp == rect)
					continue;

				if (rect.overlap (comp))
					return true;
			}

			return false;
		}

		static Meta.Rectangle rect_adjusted (Meta.Rectangle rect, int dx1, int dy1, int dx2, int dy2)
		{
			return {rect.x + dx1, rect.y + dy1, rect.width + (-dx1 + dx2), rect.height + (-dy1 + dy2)};
		}

		static Gdk.Point rect_center (Meta.Rectangle rect)
		{
			return {rect.x + rect.width / 2, rect.y + rect.height / 2};
		}

		public struct TilableWindow
		{
			Meta.Rectangle rect;
			void *id;
		}

		public static List<TilableWindow?> calculate_grid_placement (Meta.Rectangle area,
			List<TilableWindow?> windows)
		{
			uint window_count = windows.length ();
			int columns = (int)Math.ceil (Math.sqrt (window_count));
			int rows = (int)Math.ceil (window_count / (double)columns);

			// Assign slots
			int slot_width = area.width / columns;
			int slot_height = area.height / rows;

			TilableWindow?[] taken_slots = {};
			taken_slots.resize (rows * columns);

			// precalculate all slot centers
			Gdk.Point[] slot_centers = {};
			slot_centers.resize (rows * columns);
			for (int x = 0; x < columns; x++) {
				for (int y = 0; y < rows; y++) {
					slot_centers[x + y * columns] = {area.x + slot_width  * x + slot_width  / 2,
					                                 area.y + slot_height * y + slot_height / 2};
				}
			}

			// Assign each window to the closest available slot
			var tmplist = windows.copy ();
			while (tmplist.length () > 0) {
				unowned List<TilableWindow?> link = tmplist.nth (0);
				var window = link.data;
				var rect = window.rect;

				var slot_candidate = -1;
				var slot_candidate_distance = int.MAX;
				var pos = rect_center (rect);

				// all slots
				for (int i = 0; i < columns * rows; i++) {
					if (i > window_count - 1)
						break;

					var dist = squared_distance (pos, slot_centers[i]);

					if (dist < slot_candidate_distance) {
						// window is interested in this slot
						var occupier = taken_slots[i];
						if (occupier == window)
							continue;

						if (occupier == null || dist < squared_distance (rect_center (occupier.rect), slot_centers[i])) {
							// either nobody lives here, or we're better - takeover the slot if it's our best
							slot_candidate = i;
							slot_candidate_distance = dist;
						}
					}
				}

				if (slot_candidate == -1)
					continue;

				if (taken_slots[slot_candidate] != null)
					tmplist.prepend (taken_slots[slot_candidate]);

				tmplist.remove_link (link);
				taken_slots[slot_candidate] = window;
			}

			var result = new List<TilableWindow?> ();

			// see how many windows we have on the last row
			int left_over = (int)window_count - columns * (rows - 1);

			for (int slot = 0; slot < columns * rows; slot++) {
				var window = taken_slots[slot];
				// some slots might be empty
				if (window == null)
					continue;

				var rect = window.rect;

				// Work out where the slot is
				Meta.Rectangle target = {area.x + (slot % columns) * slot_width,
				                         area.y + (slot / columns) * slot_height,
				                         slot_width, 
				                         slot_height};
				target = rect_adjusted (target, 10, 10, -10, -10);

				float scale;
				if (target.width / (double)rect.width < target.height / (double)rect.height) {
					// Center vertically
					scale = target.width / (float)rect.width;
					target.y += (target.height - (int)(rect.height * scale)) / 2;
					target.height = (int)Math.floorf (rect.height * scale);
				} else {
					// Center horizontally
					scale = target.height / (float)rect.height;
					target.x += (target.width - (int)(rect.width * scale)) / 2;
					target.width = (int)Math.floorf (rect.width * scale);
				}

				// Don't scale the windows too much
				if (scale > 1.0) {
					scale = 1.0f;
					target = {rect_center (target).x - (int)Math.floorf (rect.width * scale) / 2,
					          rect_center (target).y - (int)Math.floorf (rect.height * scale) / 2,
					          (int)Math.floorf (scale * rect.width), 
					          (int)Math.floorf (scale * rect.height)};
				}

				// put the last row in the center, if necessary
				if (left_over != columns && slot >= columns * (rows - 1))
					target.x += (columns - left_over) * slot_width / 2;

				result.prepend ({ target, window.id });
			}

			result.reverse ();
			return result;
		}

		/* TODO needs porting
		public List<Meta.Rectangle?> natural_placement (Meta.Rectangle area, List<Meta.Rectangle?> windows)
		{
			Meta.Rectangle bounds = {area.x, area.y, area.width, area.height};

			var window_count = windows.length ();

			var direction = 0;
			int[] directions = new int[window_count];
			Meta.Rectangle[] rects = new Meta.Rectangle[window_count];

			for (int i = 0; i < window_count; i++) {
				// save rectangles into 4-dimensional arrays representing two corners of the rectangular: [left_x, top_y, right_x, bottom_y]
				var rect = clones.nth_data (i);
				rect = rect_adjusted(rect, -GAPS, -GAPS, GAPS, GAPS);
				rects[i] = rect;
				bounds = bounds.union (rect);

				// This is used when the window is on the edge of the screen to try to use as much screen real estate as possible.
				directions[i] = direction;
				direction++;
				if (direction == 4)
					direction = 0;
			}

			var loop_counter = 0;
			var overlap = false;
			do {
				overlap = false;
				for (var i = 0; i < rects.length; i++) {
					for (var j = 0; j < rects.length; j++) {
						if (i == j)
							continue;

						var rect = rects[i];
						var comp = rects[j];

						if (!rect.overlap (comp))
							continue;

						loop_counter ++;
						overlap = true;

						// Determine pushing direction
						Gdk.Point i_center = rect_center (rect);
						Gdk.Point j_center = rect_center (comp);
						Gdk.Point diff = {j_center.x - i_center.x, j_center.y - i_center.y};

						// Prevent dividing by zero and non-movement
						if (diff.x == 0 && diff.y == 0)
							diff.x = 1;

						// Approximate a vector of between 10px and 20px in magnitude in the same direction
						var length = Math.sqrtf (diff.x * diff.x + diff.y * diff.y);
						diff.x = (int)Math.floorf (diff.x * ACCURACY / length);
						diff.y = (int)Math.floorf (diff.y * ACCURACY / length);
						// Move both windows apart
						rect.x += -diff.x;
						rect.y += -diff.y;
						comp.x += diff.x;
						comp.y += diff.y;

						// Try to keep the bounding rect the same aspect as the screen so that more
						// screen real estate is utilised. We do this by splitting the screen into nine
						// equal sections, if the window center is in any of the corner sections pull the
						// window towards the outer corner. If it is in any of the other edge sections
						// alternate between each corner on that edge. We don't want to determine it
						// randomly as it will not produce consistant locations when using the filter.
						// Only move one window so we don't cause large amounts of unnecessary zooming
						// in some situations. We need to do this even when expanding later just in case
						// all windows are the same size.
						// (We are using an old bounding rect for this, hopefully it doesn't matter)
						var x_section = (int)Math.roundf ((rect.x - bounds.x) / (bounds.width / 3.0f));
						var y_section = (int)Math.roundf ((comp.y - bounds.y) / (bounds.height / 3.0f));

						i_center = rect_center (rect);
						diff.x = 0;
						diff.y = 0;
						if (x_section != 1 || y_section != 1) { // Remove this if you want the center to pull as well
							if (x_section == 1)
								x_section = (directions[i] / 2 == 1 ? 2 : 0);
							if (y_section == 1)
								y_section = (directions[i] % 2 == 1 ? 2 : 0);
						}
						if (x_section == 0 && y_section == 0) {
							diff.x = bounds.x - i_center.x;
							diff.y = bounds.y - i_center.y;
						}
						if (x_section == 2 && y_section == 0) {
							diff.x = bounds.x + bounds.width - i_center.x;
							diff.y = bounds.y - i_center.y;
						}
						if (x_section == 2 && y_section == 2) {
							diff.x = bounds.x + bounds.width - i_center.x;
							diff.y = bounds.y + bounds.height - i_center.y;
						}
						if (x_section == 0 && y_section == 2) {
							diff.x = bounds.x - i_center.x;
							diff.y = bounds.y + bounds.height - i_center.y;
						}
						if (diff.x != 0 || diff.y != 0) {
							length = Math.sqrtf (diff.x * diff.x + diff.y * diff.y);
							diff.x *= (int)Math.floorf (ACCURACY / length / 2.0f);
							diff.y *= (int)Math.floorf (ACCURACY / length / 2.0f);
							rect.x += diff.x;
							rect.y += diff.y;
						}

						// Update bounding rect
						bounds = bounds.union(rect);
						bounds = bounds.union(comp);

						//we took copies from the rects from our list so we need to reassign them
						rects[i] = rect;
						rects[j] = comp;
					}
				}
			} while (overlap && loop_counter < MAX_TRANSLATIONS);

			// Work out scaling by getting the most top-left and most bottom-right window coords.
			float scale = Math.fminf (Math.fminf (area.width / (float)bounds.width, area.height / (float)bounds.height), 1.0f);

			// Make bounding rect fill the screen size for later steps
			bounds.x = (int)Math.floorf (bounds.x - (area.width - bounds.width * scale) / 2);
			bounds.y = (int)Math.floorf (bounds.y - (area.height - bounds.height * scale) / 2);
			bounds.width = (int)Math.floorf (area.width / scale);
			bounds.height = (int)Math.floorf (area.height / scale);

			// Move all windows back onto the screen and set their scale
			var index = 0;
			foreach (var rect in rects) {
				rect = {(int)Math.floorf ((rect.x - bounds.x) * scale + area.x),
				        (int)Math.floorf ((rect.y - bounds.y) * scale + area.y),
				        (int)Math.floorf (rect.width * scale),
				        (int)Math.floorf (rect.height * scale)};

				rects[index] = rect;
				index++;
			}

			// fill gaps by enlarging windows
			bool moved = false;
			Meta.Rectangle border = area;
			do {
				moved = false;

				index = 0;
				foreach (var rect in rects) {

					int width_diff = ACCURACY;
					int height_diff = (int)Math.floorf ((((rect.width + width_diff) - rect.height) / 
					    (float)rect.width) * rect.height);
					int x_diff = width_diff / 2;
					int y_diff = height_diff / 2;

					//top right
					Meta.Rectangle old = rect;
					rect = {rect.x + x_diff, rect.y - y_diff - height_diff, rect.width + width_diff, rect.height + width_diff};
					if (rect_is_overlapping_any (rect, rects, border))
						rect = old;
					else
						moved = true;

					//bottom right
					old = rect;
					rect = {rect.x + x_diff, rect.y + y_diff, rect.width + width_diff, rect.height + width_diff};
					if (rect_is_overlapping_any (rect, rects, border))
						rect = old;
					else
						moved = true;

					//bottom left
					old = rect;
					rect = {rect.x - x_diff, rect.y + y_diff, rect.width + width_diff, rect.height + width_diff};
					if (rect_is_overlapping_any (rect, rects, border))
						rect = old;
					else
						moved = true;

					//top left
					old = rect;
					rect = {rect.x - x_diff, rect.y - y_diff - height_diff, rect.width + width_diff, rect.height + width_diff};
					if (rect_is_overlapping_any (rect, rects, border))
						rect = old;
					else
						moved = true;

					rects[index] = rect;
					index++;
				}
			} while (moved);

			var result = new List<Meta.Rectangle?> ();

			index = 0;
			foreach (var rect in rects) {
				var window_rect = clones.nth_data (index);

				rect = rect_adjusted (rect, GAPS, GAPS, -GAPS, -GAPS);
				scale = rect.width / (float)window_rect.width;

				if (scale > 2.0 || (scale > 1.0 && (window_rect.width > 300 || window_rect.height > 300))) {
					scale = (window_rect.width > 300 || window_rect.height > 300) ? 1.0f : 2.0f;
					rect = {rect_center (rect).x - (int)Math.floorf (window_rect.width * scale) / 2,
					        rect_center (rect).y - (int)Math.floorf (window_rect.height * scale) / 2,
					        (int)Math.floorf (window_rect.width * scale),
					        (int)Math.floorf (window_rect.height * scale)};
				}

				result.prepend (rect);
				index++;
			}

			result.reverse ();
			return result;
		}*/
	}
}
