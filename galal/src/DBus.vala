//
//  Copyright (C) 2012 - 2014 Tom Beckmann, Jacob Parker
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
	[DBus(name = "org.pantheon.gala")]
	public class DBus
	{
		static DBus ? instance;
		static WindowManager wm;

		Gee.HashMap <uint32, BlurActor> blur_actors;

		[DBus(visible = false)]
		public static void init(WindowManager _wm)
		{
			wm = _wm;

			Bus.own_name(BusType.SESSION, "org.pantheon.gala", BusNameOwnerFlags.NONE,
						(connection) => {
					if (instance == null)
					{
					instance = new DBus();
					}

					try {
					connection.register_object("/org/pantheon/gala", instance);
					} catch (Error e) { warning(e.message); }
				},
						() => {},
						() => warning("Could not acquire name\n"));

			Bus.own_name(BusType.SESSION, "org.gnome.Shell", BusNameOwnerFlags.NONE,
						(connection) => {
					try {
					connection.register_object("/org/gnome/Shell", DBusAccelerator.init(wm));
					connection.register_object("/org/gnome/Shell/Screenshot", ScreenshotManager.init(wm));
					} catch (Error e) { warning(e.message); }
				},
						() => {},
						() => critical("Could not acquire name"));

			Bus.own_name(BusType.SESSION, "org.gnome.Shell.Screenshot", BusNameOwnerFlags.REPLACE,
						() => {},
						() => {},
						() => critical("Could not acquire name"));
		}

		private DBus()
		{
			blur_actors = new Gee.HashMap <uint32, BlurActor> ();

			if (wm.background_group != null)
			{
				(wm.background_group as BackgroundContainer).changed.connect(() => background_changed());
			}
			else
			{
				assert_not_reached();
			}
		}

		public void perform_action(ActionType type)
		{
			wm.perform_action(type);
		}

		const double SATURATION_WEIGHT = 1.5;
		const double WEIGHT_THRESHOLD  = 1.0;

		class DummyOffscreenEffect : Clutter.OffscreenEffect {
			public signal void done_painting();

			public override void post_paint()
			{
				base.post_paint();
				done_painting();
			}
		}

		public struct ColorInformation
		{
			double average_red;
			double average_green;
			double average_blue;
			double mean;
			double variance;
		}

		/**
			* Emitted when the background change occured and the transition ended.
			* You can safely call get_optimal_panel_alpha then. It is not guaranteed
			* that this signal will be emitted only once per group of changes as often
			* done by GUIs. The change may not be visible to the user.
			*/
		public signal void background_changed();

		/**
			* Attaches a dummy offscreen effect to the background at monitor to get its
			* isolated color data. Then calculate the red, green and blue components of
			* the average color in that area and the mean color value and variance. All
			* variables are returned as a tuple in that order.
			*
			* @param monitor          The monitor where the panel will be placed
			* @param reference_x      X coordinate of the rectangle used to gather color data
			*                         relative to the monitor you picked. Values will be clamped
			*                         to its dimensions
			* @param reference_y      Y coordinate
			* @param reference_width  Width of the rectangle
			* @param reference_height Height of the rectangle
			*/
		public async ColorInformation get_background_color_information(int monitor,
																		int reference_x, int reference_y, int reference_width, int reference_height)
		throws DBusError
		{
			var background = wm.background_group.get_child_at_index(monitor);

			if (background == null)
			{
				throw new DBusError.INVALID_ARGS("Invalid monitor requested");
			}

			var effect = new DummyOffscreenEffect();
			background.add_effect(effect);

			var tex_width  = (int)background.width;
			var tex_height = (int)background.height;

			int x_start = reference_x;
			int y_start = reference_y;
			int width   = int.min(tex_width - reference_x, reference_width);
			int height  = int.min(tex_height - reference_y, reference_height);

			if (x_start > tex_width || x_start > tex_height || width <= 0 || height <= 0)
			{
				throw new DBusError.INVALID_ARGS("Invalid rectangle specified");
			}

			double variance = 0, mean = 0,
					rTotal = 0, gTotal = 0, bTotal = 0;

			ulong paint_signal_handler = 0;
			paint_signal_handler = effect.done_painting.connect(() => {
					SignalHandler.disconnect(effect, paint_signal_handler);
					background.remove_effect(effect);

					var texture = (Cogl.Texture)effect.get_texture();
					var pixels  = new uint8[texture.get_width() * texture.get_height() * 4];
					CoglFixes.texture_get_data(texture, Cogl.PixelFormat.BGRA_8888_PRE, 0, pixels);

					int size = width * height;

					double mean_squares = 0;
					double pixel        = 0;

					double max, min, score, delta, scoreTotal = 0,
					rTotal2 = 0, gTotal2 = 0, bTotal2 = 0;

					// code to calculate weighted average color is copied from
					// plank's lib/Drawing/DrawingService.vala average_color()
					// http://bazaar.launchpad.net/~docky-core/plank/trunk/view/head:/lib/Drawing/DrawingService.vala
					for (int y = y_start; y < height; y++)
					{
					for (int x = x_start; x < width; x++)
					{
						int i = y * width * 4 + x * 4;

						uint8 r = pixels[i];
						uint8 g = pixels[i + 1];
						uint8 b = pixels[i + 2];

						pixel = (0.3 * r + 0.6 * g + 0.11 * b) - 128f;

						min   = uint8.min(r, uint8.min(g, b));
						max   = uint8.max(r, uint8.max(g, b));
						delta = max - min;

						// prefer colored pixels over shades of grey
						score = SATURATION_WEIGHT * (delta == 0 ? 0.0 : delta / max);

						rTotal     += score * r;
						gTotal     += score * g;
						bTotal     += score * b;
						scoreTotal += score;

						rTotal += r;
						gTotal += g;
						bTotal += b;

						mean         += pixel;
						mean_squares += pixel * pixel;
					}
					}

					scoreTotal /= size;
					bTotal     /= size;
					gTotal     /= size;
					rTotal     /= size;

					if (scoreTotal > 0.0)
					{
					bTotal /= scoreTotal;
					gTotal /= scoreTotal;
					rTotal /= scoreTotal;
					}

					bTotal2 /= size * uint8.MAX;
					gTotal2 /= size * uint8.MAX;
					rTotal2 /= size * uint8.MAX;

					// combine weighted and not weighted sum depending on the average "saturation"
					// if saturation isn't reasonable enough
					// s = 0.0 -> f = 0.0 ; s = WEIGHT_THRESHOLD -> f = 1.0
					if (scoreTotal <= WEIGHT_THRESHOLD)
					{
					var f  = 1.0 / WEIGHT_THRESHOLD * scoreTotal;
					var rf = 1.0 - f;
					bTotal = bTotal * f + bTotal2 * rf;
					gTotal = gTotal * f + gTotal2 * rf;
					rTotal = rTotal * f + rTotal2 * rf;
					}

					// there shouldn't be values larger then 1.0
					var max_val = double.max(rTotal, double.max(gTotal, bTotal));
					if (max_val > 1.0)
					{
					bTotal /= max_val;
					gTotal /= max_val;
					rTotal /= max_val;
					}

					mean         /= size;
					mean_squares *= mean_squares / size;

					variance = Math.sqrt(mean_squares - mean * mean) / (double)size;

					get_background_color_information.callback ();
				});

			background.queue_redraw();

			yield;

			return({ rTotal, gTotal, bTotal, mean, variance });
		}

		/**
			* Adds a blur behind effect to a specific window.
			*
			* Makes the contents displayed behind the window blurred.
			* This effect can be only seeen when the window's background is transparent.
			* The added blur effect is applied and redrawn real time to always represent
			* what's behind the window.
			*
			* If your window is not always transparent, you should consider disabling
			* the blur effect with disable_blur_behind at the time of disabling transparency for the target window so
			* that the effect is not drawn unnecessarily.
			*
			* The x, y, width and height parameters can be used for setting a clip which the blur actor
			* covers behind the window. The clip is relative to the window coordinates.
			* If you want to exclusively constrain only the position or size of the blur effect you can pass 0's
			* for all other values you do not want to constrain, e.g: making the blur effect appear with an always
			* fixed height can be achieved by passing 0's to x, y and width parameters and the
			* requested value for the height parameter.
			*
			* Further calls to this method on the same window will update the properties of the
			* current blur effect to the new ones.
			*
			* If the effect is not supported on a system, then a DBusError.NOT_SUPPORTED error is thrown and
			* the effect is not added. Also, if the effect is technically supported but there is no suitable
			* renderer, the method will return false.
			*
			* @param xid the X window ID of the target window to enable the blur effect
			* @param x the X value in pixels of the clip, relative to the requested window
			* @param y the Y value in pixels of the clip, relative to the requested window
			* @param width the width value in pixels of the clip, relative to the requested window
			* @param height the height value in pixels of the clip, relative to the requested window
			* @param opacity the opacity of the blur effect, where 0 is invisible and 255 is opaque, can be used for effect animation
			* @return true if the blur was successfully added to the target window, false otherwise
			*/
		public bool enable_blur_behind(uint32 xid, int x, int y, int width, int height, uint8 opacity) throws Error
		{
			if (!BlurActor.get_supported(wm))
			{
				warning("Blur effect is not supported on this system");
				throw new DBusError.NOT_SUPPORTED("Blur effect is not supported on this system");
			}

			if (!BlurActor.get_enabled_by_default())
			{
				warning("Blur effect is not enabled");
				return(false);
			}

			if (!BlurActor.is_initted())
			{
				BlurActor.init(4, 3.8f, 150, wm.ui_group);
			}

			var blur_actor = blur_actors[xid];
			if (blur_actor != null)
			{
				blur_actor.blur_clip_rect = { x, y, width, height };
				blur_actor.clip_updated();
				blur_actor.opacity = opacity;
				blur_actor.queue_relayout();
				return(true);
			}

			var screen = wm.get_screen();
			foreach (unowned Meta.WindowActor window_actor in Meta.Compositor.get_window_actors(screen))
			{
				var window = window_actor.get_meta_window();
				if (window.get_xwindow() == xid)
				{
					var actor = new BlurActor(window_actor);
					actor.set_name("blur-actor");
					actor.destroy.connect(on_blur_actor_destroyed);
					actor.blur_clip_rect = { x, y, width, height };
					actor.opacity        = opacity;

					window_actor.insert_child_below(actor, null);
					blur_actors[xid] = actor;
					return(true);
				}
			}

			return(false);
		}

		void on_blur_actor_destroyed(Clutter.Actor actor)
		{
			bool   found = false;
			uint32 xid   = 0;

			foreach (var entry in blur_actors.entries)
			{
				if (entry.value == actor)
				{
					xid   = entry.key;
					found = true;
					break;
				}
			}

			if (found)
			{
				blur_actors.unset(xid);
			}

			if (blur_actors.size == 0)
			{
				BlurActor.deinit();
			}
		}

		/**
			* Disables the blur effect behind the specified window.
			*
			* Finds and removes the blur actor added behind the specified
			* window.
			*
			* This method will throw an error when the specified X window ID
			* does not have an associated blur actor with it.
			*
			* @param xid the X window ID of the target window to disable the blur effect
			*/
		public void disable_blur_behind(uint32 xid) throws Error
		{
			var actor = blur_actors[xid];

			if (actor != null)
			{
				actor.destroy();
			}
			else
			{
				throw new DBusError.FAILED("Blur actor was not found for the specified window ID");
			}
		}
	}
}
