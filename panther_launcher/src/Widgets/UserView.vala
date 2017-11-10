// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//
//  Copyright (C) 2017 Nick Wilkins
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

using Gtk;

namespace Panther.Widgets {

	public class UserView : Gtk.Box {

		Gtk.Image face;
		Gtk.Grid grid;
		Gtk.Label name;
		Gtk.Button button;

		public UserView () {
			grid = new Gtk.Grid();
			button = new Gtk.Button();

			name = new Gtk.Label ("Nick");
			face = new Gtk.Image.from_pixbuf(new Gdk.Pixbuf.from_file_at_scale ("/home/nick/.face", Panther.settings.icon_size,
                                                                     Panther.settings.icon_size, true));

			button.set_image(face);
			button.set_image_position(Gtk.PositionType.LEFT);
			button.set_label("Nick");
			button.set_relief(Gtk.ReliefStyle.NONE);

            grid.orientation = Gtk.Orientation.HORIZONTAL;
            grid.row_spacing = 30;
            

            grid.add(button);
			
			add(grid);
		}
	}
}