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
	public class Animation : Object
	{
		public string filename { get; construct; }
		public string[] key_frame_files { get; private set; default = {}; }
		public double transition_progress { get; private set; default = 0.0; }
		public double transition_duration { get; private set; default = 0.0; }
		public bool loaded { get; private set; default = false; }

		Gnome.BGSlideShow? show = null;

		public Animation (string filename)
		{
			Object (filename: filename);
		}

		public async void load ()
		{
			show = new Gnome.BGSlideShow (filename);

			show.load_async (null, (obj, res) => {
				loaded = true;

				load.callback ();
			});

			yield;
		}

		public void update (Meta.Rectangle monitor)
		{
			string[] key_frame_files = {};

			if (show == null)
				return;

			if (show.get_num_slides () < 1)
				return;

			double progress, duration;
			bool is_fixed;
			string file1, file2;
			show.get_current_slide (monitor.width, monitor.height, out progress, out duration, out is_fixed, out file1, out file2);

			transition_duration = duration;
			transition_progress = progress;

			if (file1 != null)
				key_frame_files += file1;

			if (file2 != null)
				key_frame_files += file2;

			this.key_frame_files = key_frame_files;
		}
	}
}

