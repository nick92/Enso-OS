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
	public class ConfirmationNotification : Notification
	{
		const int DURATION = 2000;
		const int PROGRESS_HEIGHT = 6;

		public bool has_progress { get; private set; }

		int _progress;
		public int progress {
			get {
				return _progress;
			}
			private set {
				_progress = value;
				content.invalidate ();
			}
		}

		public string confirmation_type { get; private set; }

		int old_progress;

		public ConfirmationNotification (uint32 id, Gdk.Pixbuf? icon, bool icon_only,
			int progress, string confirmation_type)
		{
			Object (id: id, icon: icon, urgency: NotificationUrgency.LOW, expire_timeout: DURATION);

			this.icon_only = icon_only;
			this.has_progress = progress > -1;
			this.progress = progress;
			this.confirmation_type = confirmation_type;
		}

		public override void update_allocation (out float content_height, AllocationFlags flags)
		{
			content_height = ICON_SIZE;
		}

		public override void draw_content (Cairo.Context cr)
		{
			if (!has_progress)
				return;

			var x = MARGIN + PADDING + ICON_SIZE + SPACING;
			var y = MARGIN + PADDING + (ICON_SIZE - PROGRESS_HEIGHT) / 2;
			var width = WIDTH - x - MARGIN;

			if (!transitioning)
				draw_progress_bar (cr, x, y, width, progress);
			else {
				Granite.Drawing.Utilities.cairo_rounded_rectangle (cr, MARGIN, MARGIN, WIDTH - MARGIN * 2, ICON_SIZE + PADDING * 2, 4);
				cr.clip ();

				draw_progress_bar (cr, x, y + animation_slide_y_offset, width, old_progress);
				draw_progress_bar (cr, x, y + animation_slide_y_offset - animation_slide_height, width, progress);

				cr.reset_clip ();
			}
		}

		void draw_progress_bar (Cairo.Context cr, int x, float y, int width, int progress)
		{
			var fraction = (int) Math.floor (progress.clamp (0, 100) / 100.0 * width);

			Granite.Drawing.Utilities.cairo_rounded_rectangle (cr, x, y, width,
				PROGRESS_HEIGHT, PROGRESS_HEIGHT / 2);
			cr.set_source_rgb (0.8, 0.8, 0.8);
			cr.fill ();

			if (progress > 0) {
				Granite.Drawing.Utilities.cairo_rounded_rectangle (cr, x, y, fraction,
					PROGRESS_HEIGHT, PROGRESS_HEIGHT / 2);
				cr.set_source_rgb (0.3, 0.3, 0.3);
				cr.fill ();
			}
		}

		protected override void update_slide_animation ()
		{
			// just trigger the draw function, which will move our progress bar down
			content.invalidate ();
		}

		public void update (Gdk.Pixbuf? icon, int progress, string confirmation_type,
			bool icon_only)
		{
			if (this.confirmation_type != confirmation_type) {
				this.confirmation_type = confirmation_type;

				old_progress = this.progress;

				play_update_transition (ICON_SIZE + PADDING * 2);
			}

			if (this.icon_only != icon_only) {
				this.icon_only = icon_only;
				queue_relayout ();
			}

			this.has_progress = progress > -1;
			this.progress = progress;

			update_base (icon, DURATION);
		}
	}
}
