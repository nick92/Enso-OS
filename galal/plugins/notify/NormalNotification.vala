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
	/**
	 * Wrapper class only containing the summary and body label. Allows us to
	 * instantiate the content very easily for when we need to slide the old
	 * and new content down.
	 */
	class NormalNotificationContent : Actor
	{
		static Regex entity_regex;
		static Regex tag_regex;

		static construct
		{
			try {
				entity_regex = new Regex ("&(?!amp;|quot;|apos;|lt;|gt;)");
				tag_regex = new Regex ("<(?!\\/?[biu]>)");
			} catch (Error e) {}
		}

		const int LABEL_SPACING = 2;

		Text summary_label;
		Text body_label;

		construct
		{
			summary_label = new Text.with_text (null, "");
			summary_label.line_wrap = true;
			summary_label.use_markup = true;
			summary_label.line_wrap_mode = Pango.WrapMode.WORD_CHAR;

			body_label = new Text.with_text (null, "");
			body_label.line_wrap = true;
			body_label.use_markup = true;
			body_label.line_wrap_mode = Pango.WrapMode.WORD_CHAR;

			var style_path = new Gtk.WidgetPath ();
			style_path.append_type (typeof (Gtk.Window));
			style_path.append_type (typeof (Gtk.EventBox));
			style_path.iter_add_class (1, "gala-notification");
			style_path.append_type (typeof (Gtk.Label));

			var label_style_context = new Gtk.StyleContext ();
			label_style_context.add_provider (Notification.default_css, Gtk.STYLE_PROVIDER_PRIORITY_FALLBACK);
			label_style_context.set_path (style_path);

			Gdk.RGBA color;

			label_style_context.save ();
			label_style_context.add_class ("title");
			color = label_style_context.get_color (Gtk.StateFlags.NORMAL);
			summary_label.color = {
				(uint8) (color.red * 255),
				(uint8) (color.green * 255),
				(uint8) (color.blue * 255),
				(uint8) (color.alpha * 255)
			};
			label_style_context.restore ();

			label_style_context.save ();
			label_style_context.add_class ("label");
			color = label_style_context.get_color (Gtk.StateFlags.NORMAL);
			body_label.color = {
				(uint8) (color.red * 255),
				(uint8) (color.green * 255),
				(uint8) (color.blue * 255),
				(uint8) (color.alpha * 255)
			};
			label_style_context.restore ();

			add_child (summary_label);
			add_child (body_label);
		}

		public void set_values (string summary, string body)
		{
			summary_label.set_markup ("<b>%s</b>".printf (fix_markup (summary)));
			body_label.set_markup (fix_markup (body));
		}

		public override void get_preferred_height (float for_width, out float min_height, out float nat_height)
		{
			float label_height;
			get_allocation_values (null, null, null, null, out label_height, null);

			min_height = nat_height = label_height;
		}

		public override void allocate (ActorBox box, AllocationFlags flags)
		{
			float label_x, label_width, summary_height, body_height, label_height, label_y;
			get_allocation_values (out label_x, out label_width, out summary_height,
				out body_height, out label_height, out label_y);

			var summary_alloc = ActorBox ();
			summary_alloc.set_origin (label_x, label_y);
			summary_alloc.set_size (label_width, summary_height);
			summary_label.allocate (summary_alloc, flags);

			var body_alloc = ActorBox ();
			body_alloc.set_origin (label_x, label_y + summary_height + LABEL_SPACING);
			body_alloc.set_size (label_width, body_height);
			body_label.allocate (body_alloc, flags);

			base.allocate (box, flags);
		}

		void get_allocation_values (out float label_x, out float label_width, out float summary_height,
			out float body_height, out float label_height, out float label_y)
		{
			var height = Notification.ICON_SIZE;

			label_x = Notification.MARGIN + Notification.PADDING + height + Notification.SPACING;
			label_width = Notification.WIDTH - label_x - Notification.MARGIN - Notification.SPACING;

			summary_label.get_preferred_height (label_width, null, out summary_height);
			body_label.get_preferred_height (label_width, null, out body_height);

			label_height = summary_height + LABEL_SPACING + body_height;
			label_y = Notification.MARGIN + Notification.PADDING;
			// center
			if (label_height < height) {
				label_y += (height - (int) label_height) / 2;
				label_height = height;
			}
		}

		/**
		 * Copied from gnome-shell, fixes the mess of markup that is sent to us
		 */
		string fix_markup (string markup)
		{
			var text = markup;

			try {
				text = entity_regex.replace (markup, markup.length, 0, "&amp;");
				text = tag_regex.replace (text, text.length, 0, "&lt;");
			} catch (Error e) {}

			return text;
		}
	}

	public class NormalNotification : Notification
	{
		public string summary { get; construct set; }
		public string body { get; construct set; }
		public uint32 sender_pid { get; construct; }
		public string[] notification_actions { get; construct set; }
		public Screen screen { get; construct; }

		Actor content_container;
		NormalNotificationContent notification_content;
		NormalNotificationContent? old_notification_content = null;

		public NormalNotification (Screen screen, uint32 id, string summary, string body, Gdk.Pixbuf? icon,
			NotificationUrgency urgency, int32 expire_timeout, uint32 pid, string[] actions)
		{
			Object (
				id: id,
				icon: icon,
				urgency: urgency,
				expire_timeout: expire_timeout,
				screen: screen,
				summary: summary,
				body: body,
				sender_pid: pid,
				notification_actions: actions
			);
		}

		construct
		{
			content_container = new Actor ();

			notification_content = new NormalNotificationContent ();
			notification_content.set_values (summary, body);

			content_container.add_child (notification_content);
			insert_child_below (content_container, null);
		}

		public void update (string summary, string body, Gdk.Pixbuf? icon, int32 expire_timeout,
			string[] actions)
		{
			var visible_change = this.summary != summary || this.body != body;

			if (visible_change) {
				if (old_notification_content != null)
					old_notification_content.destroy ();

				old_notification_content = new NormalNotificationContent ();
				old_notification_content.set_values (this.summary, this.body);

				content_container.add_child (old_notification_content);

				this.summary = summary;
				this.body = body;
				notification_content.set_values (summary, body);

				float content_height, old_content_height;
				notification_content.get_preferred_height (0, null, out content_height);
				old_notification_content.get_preferred_height (0, null, out old_content_height);

				content_height = float.max (content_height, old_content_height);

				play_update_transition (content_height + PADDING * 2);

				get_transition ("switch").completed.connect (() => {
					if (old_notification_content != null)
						old_notification_content.destroy ();
					old_notification_content = null;
				});
			}

			notification_actions = actions;
			update_base (icon, expire_timeout);
		}

		protected override void update_slide_animation ()
		{
			if (old_notification_content != null)
				old_notification_content.y = animation_slide_y_offset;

			notification_content.y = animation_slide_y_offset - animation_slide_height;
		}

		public override void update_allocation (out float content_height, AllocationFlags flags)
		{
			var box = ActorBox ();
			box.set_origin (0, 0);
			box.set_size (width, height);

			content_container.allocate (box, flags);

			// the for_width is not needed in our implementation of get_preferred_height as we
			// assume a constant width
			notification_content.get_preferred_height (0, null, out content_height);

			content_container.set_clip (MARGIN, MARGIN, MARGIN * 2 + WIDTH, content_height + PADDING * 2);
		}

		public override void get_preferred_height (float for_width, out float min_height, out float nat_height)
		{
			float content_height;
			notification_content.get_preferred_height (for_width, null, out content_height);

			min_height = nat_height = content_height + (MARGIN + PADDING) * 2;
		}

		public override void activate ()
		{
			// we currently only support the default action, which can be triggered by clicking
			// on the notification according to spec
			for (var i = 0; i < notification_actions.length; i += 2) {
				if (notification_actions[i] == "default") {
					action_invoked (id, "default");
					dismiss ();

					return;
				}
			}

			// if no default action has been set, we fallback to trying to find a window for the
			// notification's sender process
			unowned Meta.Window? window = get_window ();
			if (window != null) {
				unowned Meta.Workspace workspace = window.get_workspace ();
				var time = screen.get_display ().get_current_time ();

				if (workspace != screen.get_active_workspace ())
					workspace.activate_with_focus (window, time);
				else
					window.activate (time);

				dismiss ();
			}
		}

		unowned Meta.Window? get_window ()
		{
			if (sender_pid == 0)
				return null;

			foreach (unowned Meta.WindowActor actor in Meta.Compositor.get_window_actors (screen)) {
				if (actor.is_destroyed ())
					continue;

				unowned Meta.Window window = actor.get_meta_window ();

				// the windows are sorted by stacking order when returned
				// from meta_get_window_actors, so we can just pick the first
				// one we find and have a pretty good match
				if (window.get_pid () == sender_pid)
					return window;
			}

			return null;
		}

		void dismiss ()
		{
			closed (id, NotificationClosedReason.DISMISSED);
			close ();
		}
	}
}

