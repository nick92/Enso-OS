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

namespace Gala
{
	public class TextShadowEffect : Clutter.Effect
	{
		int _offset_y;
		public int offset_y {
			get { return _offset_y; }
			set { _offset_y = value; update (); }
		}

		int _offset_x;
		public int offset_x {
			get { return _offset_x; }
			set { _offset_x = value; update (); }
		}

		uint8 _opacity;
		public uint8 opacity {
			get { return _opacity; }
			set { _opacity = value; update (); }
		}

		public TextShadowEffect (int offset_x, int offset_y, uint8 opacity)
		{
			_offset_x = offset_x;
			_offset_y = offset_y;
			_opacity  = opacity;
		}

		public override bool pre_paint ()
		{
			var layout = ((Clutter.Text)get_actor ()).get_layout ();
			Cogl.pango_render_layout (layout, offset_x, offset_y, Cogl.Color.from_4ub (0, 0, 0, opacity), 0);

			return true;
		}

		public void update ()
		{
			if (get_actor () != null)
				get_actor ().queue_redraw ();
		}
	}
}

