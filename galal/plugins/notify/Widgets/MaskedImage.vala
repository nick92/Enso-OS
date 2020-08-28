/*
* Copyright 2019 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
*/

using Clutter;
using Meta;

namespace Gala.Plugins.Notify {
    public class MaskedImage : Gtk.Overlay {
        private const int ICON_SIZE = 48;

        public Gdk.Pixbuf pixbuf { get; construct; }

        public MaskedImage (Gdk.Pixbuf pixbuf) {
            Object (pixbuf: pixbuf);
        }

        construct {
            var mask = new Gtk.Image.from_resource ("/io/elementary/desktop/gala/mask.svg");
            mask.pixel_size = ICON_SIZE;

            var scale = get_style_context ().get_scale ();

            var image = new Gtk.Image ();
            image.gicon = mask_pixbuf (pixbuf, scale);
            image.pixel_size = ICON_SIZE;

            add (image);
            add_overlay (mask);
        }

        private static Gdk.Pixbuf? mask_pixbuf (Gdk.Pixbuf pixbuf, int scale) {
            var size = ICON_SIZE * scale;
            var mask_offset = 4 * scale;
            var mask_size_offset = mask_offset * 2;
            var mask_size = ICON_SIZE * scale;
            var offset_x = mask_offset;
            var offset_y = mask_offset + scale;
            size = size - mask_size_offset;

            var input = pixbuf.scale_simple (size, size, Gdk.InterpType.BILINEAR);
            var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, mask_size, mask_size);
            var cr = new Cairo.Context (surface);

            Granite.Drawing.Utilities.cairo_rounded_rectangle (cr, offset_x, offset_y, size, size, mask_offset);
            cr.clip ();

            Gdk.cairo_set_source_pixbuf (cr, input, offset_x, offset_y);
            cr.paint ();

            return Gdk.pixbuf_get_from_surface (surface, 0, 0, mask_size, mask_size);
        }
    }
}