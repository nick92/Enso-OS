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
    public class Confirmation : AbstractBubble {
        public new string icon_name { get; construct set; }
        public double progress { get; construct set; }

        public Confirmation (string icon_name, double progress) {
            Object (
                icon_name: icon_name,
                progress: progress
            );
        }

        construct {
            var image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG);
            image.valign = Gtk.Align.START;
            image.pixel_size = 48;

            var progressbar = new Gtk.ProgressBar ();
            progressbar.hexpand = true;
            progressbar.valign = Gtk.Align.CENTER;
            progressbar.margin_end = 6;

            var contents = new Gtk.Grid ();
            contents.column_spacing = 6;
            contents.attach (image, 0, 0);
            contents.attach (progressbar, 1, 0);

            content_area.add (contents);

            get_style_context ().add_class ("confirmation");

            bind_property ("icon-name", image, "icon-name");
            bind_property ("progress", progressbar, "fraction");

            notify["progress"].connect (() => {
                stop_timeout ();
                start_timeout (2000);
            });

            leave_notify_event.connect (() => {
                start_timeout (2000);
                return Gdk.EVENT_PROPAGATE;
            });
        }
    }
}
