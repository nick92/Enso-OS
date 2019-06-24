/***

    Copyright (C) 2019 Enso Developers

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as
    published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses>

***/

namespace Welcome {

	public class WelcomeView : Gtk.EventBox {

		private Granite.Widgets.Welcome enso_welcome;
		private Gtk.Image rose_image;
		private Gtk.Grid grid;

		construct {
			/**
           *  Initialize the GUI components
   	 */
      enso_welcome = new Granite.Widgets.Welcome (_("Welcome to Enso!"), _("0.3.1 - Dancing Daisy"));

			rose_image = new Gtk.Image.from_pixbuf (new Gdk.Pixbuf.from_resource_at_scale ("/org/enso/welcome/icon/flower.svg", 400, 400, true));

			grid = new Gtk.Grid ();
			grid.expand = true;   // expand the box to fill the whole window
      grid.row_homogeneous = false;
			grid.attach (enso_welcome, 0, 0, 1, 1);
			grid.attach (rose_image, 0, 1, 1, 1);

			add(grid);
		}
	}

}
