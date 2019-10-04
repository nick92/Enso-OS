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
	public abstract class Notification : Actor
	{
		public static Gtk.CssProvider? default_css = null;

		public const int WIDTH = 300;
		public const int ICON_SIZE = 48;
		public const int MARGIN = 12;

		public const int SPACING = 6;
		public const int PADDING = 4;

		public signal void action_invoked (uint32 id, string action);
		public signal void closed (uint32 id, uint32 reason);

		public uint32 id { get; construct; }
		public Gdk.Pixbuf? icon { get; construct set; }
		public NotificationUrgency urgency { get; construct; }
		public int32 expire_timeout { get; construct set; }

		public uint64 relevancy_time { get; private set; }
		public bool being_destroyed { get; private set; default = false; }

		protected bool icon_only { get; protected set; default = false; }
		protected Clutter.Texture icon_texture { get; private set; }
		protected Actor icon_container { get; private set; }

		/**
		 * Whether we're currently sliding content for an update animation
		 */
		protected bool transitioning { get; private set; default = false; }

		Clutter.Actor close_button;

		protected Gtk.StyleContext style_context { get; private set; }

		uint remove_timeout = 0;

		// temporary things needed for the slide transition
		protected float animation_slide_height { get; private set; }
		Clutter.Texture old_texture;
		float _animation_slide_y_offset = 0.0f;
		public float animation_slide_y_offset {
			get {
				return _animation_slide_y_offset;
			}
			set {
				_animation_slide_y_offset = value;

				icon_texture.y = -animation_slide_height + _animation_slide_y_offset;
				old_texture.y = _animation_slide_y_offset;

				update_slide_animation ();
			}
		}

		protected Notification (uint32 id, Gdk.Pixbuf? icon, NotificationUrgency urgency,
			int32 expire_timeout)
		{
			Object (
				id: id,
				icon: icon,
				urgency: urgency,
				expire_timeout: expire_timeout
			);
		}

		construct
		{
#if HAS_MUTTER326
			var scale = Meta.Backend.get_backend ().get_settings ().get_ui_scaling_factor ();
#else
			var scale = 1;
#endif
			relevancy_time = new DateTime.now_local ().to_unix ();
			width = (WIDTH + MARGIN * 2) * scale;
			reactive = true;
			set_pivot_point (0.5f, 0.5f);

			icon_texture = new Clutter.Texture ();
			icon_texture.set_pivot_point (0.5f, 0.5f);

			icon_container = new Actor ();
			icon_container.add_child (icon_texture);

			close_button = Utils.create_close_button ();
			close_button.opacity = 0;
			close_button.reactive = true;
			close_button.set_easing_duration (300);

			var close_click = new ClickAction ();
			close_click.clicked.connect (() => {
				closed (id, NotificationClosedReason.DISMISSED);
				close ();
			});
			close_button.add_action (close_click);

			add_child (icon_container);
			add_child (close_button);

			if (default_css == null) {
				default_css = new Gtk.CssProvider ();
				try {
					default_css.load_from_path (Config.PKGDATADIR + "/gala.css");
				} catch (Error e) {
					warning ("Loading default styles failed: %s", e.message);
				}
			}

			var style_path = new Gtk.WidgetPath ();
			style_path.append_type (typeof (Gtk.Window));
			style_path.append_type (typeof (Gtk.EventBox));

			style_context = new Gtk.StyleContext ();
			style_context.add_provider (default_css, Gtk.STYLE_PROVIDER_PRIORITY_FALLBACK);
			style_context.add_class ("gala-notification");
			style_context.set_path (style_path);
			style_context.set_scale (scale);

			var label_style_path = style_path.copy ();
			label_style_path.iter_add_class (1, "gala-notification");
			label_style_path.append_type (typeof (Gtk.Label));

			var canvas = new Canvas ();
			canvas.draw.connect (draw);
			content = canvas;

			set_values ();

			var click = new ClickAction ();
			click.clicked.connect (() => {
				activate ();
			});
			add_action (click);

			open ();
		}

		public void open () {
			var entry = new TransitionGroup ();
			entry.remove_on_complete = true;
			entry.duration = 400;

			var opacity_transition = new PropertyTransition ("opacity");
			opacity_transition.set_from_value (0);
			opacity_transition.set_to_value (255);

			var flip_transition = new KeyframeTransition ("rotation-angle-x");
			flip_transition.set_from_value (90.0);
			flip_transition.set_to_value (0.0);
			flip_transition.set_key_frames ({ 0.6 });
			flip_transition.set_values ({ -10.0 });

			entry.add_transition (opacity_transition);
			entry.add_transition (flip_transition);
			add_transition ("entry", entry);

			switch (urgency) {
				case NotificationUrgency.LOW:
				case NotificationUrgency.NORMAL:
					return;
				case NotificationUrgency.CRITICAL:
					var icon_entry = new TransitionGroup ();
					icon_entry.duration = 1000;
					icon_entry.remove_on_complete = true;
					icon_entry.progress_mode = AnimationMode.EASE_IN_OUT_CUBIC;

					double[] keyframes = { 0.2, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0 };
					GLib.Value[] scale = { 0.0, 1.2, 1.6, 1.6, 1.6, 1.6, 1.2, 1.0 };

					var rotate_transition = new KeyframeTransition ("rotation-angle-z");
					rotate_transition.set_from_value (30.0);
					rotate_transition.set_to_value (0.0);
					rotate_transition.set_key_frames (keyframes);
					rotate_transition.set_values ({ 30.0, -30.0, 30.0, -20.0, 10.0, -5.0, 2.0, 0.0 });

					var scale_x_transition = new KeyframeTransition ("scale-x");
					scale_x_transition.set_from_value (0.0);
					scale_x_transition.set_to_value (1.0);
					scale_x_transition.set_key_frames (keyframes);
					scale_x_transition.set_values (scale);

					var scale_y_transition = new KeyframeTransition ("scale-y");
					scale_y_transition.set_from_value (0.0);
					scale_y_transition.set_to_value (1.0);
					scale_y_transition.set_key_frames (keyframes);
					scale_y_transition.set_values (scale);

					icon_entry.add_transition (rotate_transition);
					icon_entry.add_transition (scale_x_transition);
					icon_entry.add_transition (scale_y_transition);

					icon_texture.add_transition ("entry", icon_entry);
					return;
			}
		}

		public void close ()
		{
			set_easing_duration (100);

			set_easing_mode (AnimationMode.EASE_IN_QUAD);
			opacity = 0;

			x = (WIDTH + MARGIN * 2) * style_context.get_scale ();

			being_destroyed = true;
			var transition = get_transition ("x");
			if (transition != null)
				transition.completed.connect (() => destroy ());
			else
				destroy ();
		}

		protected void update_base (Gdk.Pixbuf? icon, int32 expire_timeout)
		{
			this.icon = icon;
			this.expire_timeout = expire_timeout;
			this.relevancy_time = new DateTime.now_local ().to_unix ();

			set_values ();
		}

		void set_values ()
		{
			if (icon != null) {
				try {
					icon_texture.set_from_rgb_data (icon.get_pixels (), icon.get_has_alpha (),
						icon.get_width (), icon.get_height (),
						icon.get_rowstride (), (icon.get_has_alpha () ? 4 : 3), 0);
				} catch (Error e) {}
			}

			set_timeout ();
		}

		void set_timeout ()
		{
			// crtitical notifications have to be dismissed manually
			if (expire_timeout <= 0 || urgency == NotificationUrgency.CRITICAL)
				return;

			clear_timeout ();

			remove_timeout = Timeout.add (expire_timeout, () => {
				closed (id, NotificationClosedReason.EXPIRED);
				close ();
				remove_timeout = 0;
				return false;
			});
		}

		void clear_timeout ()
		{
			if (remove_timeout != 0) {
				Source.remove (remove_timeout);
				remove_timeout = 0;
			}
		}

		public override bool enter_event (CrossingEvent event)
		{
			close_button.opacity = 255;

			clear_timeout ();

			return true;
		}

		public override bool leave_event (CrossingEvent event)
		{
			close_button.opacity = 0;

			// TODO consider decreasing the timeout now or calculating the remaining
			set_timeout ();

			return true;
		}

		public virtual void activate ()
		{
		}

		public virtual void draw_content (Cairo.Context cr)
		{
		}

		public abstract void update_allocation (out float content_height, AllocationFlags flags);

		public override void allocate (ActorBox box, AllocationFlags flags)
		{
			var icon_alloc = ActorBox ();

			var scale = style_context.get_scale ();
			var scaled_width = WIDTH * scale;
			var scaled_icon_size = ICON_SIZE * scale;
			var scaled_margin_padding = (MARGIN + PADDING) * scale;
			icon_alloc.set_origin (icon_only ? (scaled_width - scaled_icon_size) / 2 : scaled_margin_padding, scaled_margin_padding);
			icon_alloc.set_size (scaled_icon_size, scaled_icon_size);
			icon_container.allocate (icon_alloc, flags);

			var close_alloc = ActorBox ();
			close_alloc.set_origin (scaled_margin_padding - close_button.width / 2,
				scaled_margin_padding - close_button.height / 2);
			close_alloc.set_size (close_button.width, close_button.height);
			close_button.allocate (close_alloc, flags);

			float content_height;
			update_allocation (out content_height, flags);
			box.set_size (MARGIN * 2 * scale + scaled_width, scaled_margin_padding * 2 + content_height);

			base.allocate (box, flags);

			var canvas = (Canvas) content;
			var canvas_width = (int) box.get_width ();
			var canvas_height = (int) box.get_height ();
			if (canvas.width != canvas_width || canvas.height != canvas_height)
				canvas.set_size (canvas_width, canvas_height);
		}

		public override void get_preferred_height (float for_width, out float min_height, out float nat_height)
		{
			min_height = nat_height = (ICON_SIZE + (MARGIN + PADDING) * 2) * style_context.get_scale ();
		}

		protected void play_update_transition (float slide_height)
		{
			Transition transition;
			if ((transition = get_transition ("switch")) != null) {
				transition.completed ();
				remove_transition ("switch");
			}

			animation_slide_height = slide_height;

			var scale = style_context.get_scale ();
			var scaled_padding = PADDING * scale;
			var scaled_icon_size = ICON_SIZE * scale;
			old_texture = new Clutter.Texture ();
			icon_container.add_child (old_texture);
			icon_container.set_clip (0, -scaled_padding, scaled_icon_size, scaled_icon_size + scaled_padding * 2);

			if (icon != null) {
				try {
					old_texture.set_from_rgb_data (icon.get_pixels (), icon.get_has_alpha (),
						icon.get_width (), icon.get_height (),
						icon.get_rowstride (), (icon.get_has_alpha () ? 4 : 3), 0);
				} catch (Error e) {}
			}

			transition = new PropertyTransition ("animation-slide-y-offset");
			transition.duration = 200;
			transition.progress_mode = AnimationMode.EASE_IN_OUT_QUAD;
			transition.set_from_value (0.0f);
			transition.set_to_value (animation_slide_height);
			transition.remove_on_complete = true;

			transition.completed.connect (() => {
				old_texture.destroy ();
				icon_container.remove_clip ();
				_animation_slide_y_offset = 0;
				transitioning = false;
			});

			add_transition ("switch", transition);
			transitioning = true;
		}

		protected virtual void update_slide_animation ()
		{
		}

		bool draw (Cairo.Context cr)
		{
			var canvas = (Canvas) content;

			var scale = style_context.get_scale ();
			var x = MARGIN;
			var y = MARGIN;
			var width = canvas.width / scale - MARGIN * 2;
			var height = canvas.height / scale - MARGIN * 2;
			cr.set_operator (Cairo.Operator.CLEAR);
			cr.paint ();
			cr.set_operator (Cairo.Operator.OVER);

			cr.save ();
			cr.scale (scale, scale);
			style_context.render_background (cr, x, y, width, height);
			style_context.render_frame (cr, x, y, width, height);
			cr.restore ();

			draw_content (cr);

			return false;
		}
	}
}
