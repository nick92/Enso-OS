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

namespace Gala {
    /**
     * Creates a new ClutterTexture with an icon for the window at the given size.
     * This is recommended way to grab an icon for a window as this method will make
     * sure the icon is updated if it becomes available at a later point.
     */
#if HAS_MUTTER336
    public class WindowIcon : Clutter.Actor {
#else
    public class WindowIcon : Clutter.Texture {
#endif
        static Bamf.Matcher matcher;

        static construct {
            matcher = Bamf.Matcher.get_default ();
        }

        public Meta.Window window { get; construct; }
        public int icon_size { get; construct; }
        public int scale { get; construct; }

        /**
         * If set to true, the SafeWindowClone will destroy itself when the connected
         * window is unmanaged
         */
        public bool destroy_on_unmanaged {
            get {
                return _destroy_on_unmanaged;
            }
            construct set {
                if (_destroy_on_unmanaged == value)
                    return;

                _destroy_on_unmanaged = value;
                if (_destroy_on_unmanaged)
                    window.unmanaged.connect (unmanaged);
                else
                    window.unmanaged.disconnect (unmanaged);
            }
        }

        bool _destroy_on_unmanaged = false;
        bool loaded = false;
        uint32 xid;

        /**
         * Creates a new WindowIcon
         *
         * @param window               The window for which to create the icon
         * @param icon_size            The size of the icon in pixels
         * @param scale                The desired scale of the icon
         * @param destroy_on_unmanaged see destroy_on_unmanaged property
         */
        public WindowIcon (Meta.Window window, int icon_size, int scale = 1, bool destroy_on_unmanaged = false) {
            Object (window: window,
                icon_size: icon_size,
                destroy_on_unmanaged: destroy_on_unmanaged,
                scale: scale);
        }

        construct {
            width = icon_size * scale;
            height = icon_size * scale;
            xid = (uint32) window.get_xwindow ();

            // new windows often reach mutter earlier than bamf, that's why
            // we have to wait until the next window opens and hope that it's
            // ours so we can get a proper icon instead of the default fallback.
            var app = matcher.get_application_for_xid (xid);
            if (app == null)
                matcher.view_opened.connect (retry_load);
            else
                loaded = true;

            update_texture (true);
        }

        ~WindowIcon () {
            if (!loaded)
                matcher.view_opened.disconnect (retry_load);
        }

        void retry_load (Bamf.View view) {
            var app = matcher.get_application_for_xid (xid);

            // retry only once
            loaded = true;
            matcher.view_opened.disconnect (retry_load);

            if (app == null)
                return;

            update_texture (false);
        }

        void update_texture (bool initial) {
            var pixbuf = Gala.Utils.get_icon_for_xid (xid, icon_size, scale, !initial);

            try {
#if HAS_MUTTER336
                var image = new Clutter.Image ();
                Cogl.PixelFormat pixel_format = (pixbuf.get_has_alpha () ? Cogl.PixelFormat.RGBA_8888 : Cogl.PixelFormat.RGB_888);
                image.set_data (pixbuf.get_pixels (), pixel_format, pixbuf.width, pixbuf.height, pixbuf.rowstride);
                set_content (image);
#else
                set_from_rgb_data (pixbuf.get_pixels (), pixbuf.get_has_alpha (),
                pixbuf.get_width (), pixbuf.get_height (),
                pixbuf.get_rowstride (), (pixbuf.get_has_alpha () ? 4 : 3), 0);
#endif
            } catch (Error e) {}
        }

        void unmanaged (Meta.Window window) {
            destroy ();
        }
    }
}
