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

namespace Gala {
#if HAS_MUTTER332
    public class SystemBackground : GLib.Object {
#else
    public class SystemBackground : Meta.BackgroundActor {
#endif
        const Clutter.Color DEFAULT_BACKGROUND_COLOR = { 0x2e, 0x34, 0x36, 0xff };

        static Meta.Background? system_background = null;
#if HAS_MUTTER332
    public Meta.BackgroundActor background_actor { get; construct; }
#endif

        public signal void loaded ();

#if HAS_MUTTER330
        public SystemBackground (Meta.Display display) {
#if HAS_MUTTER332
            Object (background_actor: new Meta.BackgroundActor (display, 0));
#else
            Object (meta_display: display, monitor: 0);
#endif
        }
#else
        public SystemBackground (Meta.Screen screen) {
            Object (meta_screen: screen, monitor: 0);
        }
#endif

        construct {
            var background_file = GLib.File.new_for_uri ("resource:///io/elementary/desktop/gala/texture.png");
            var appearance_settings = new GLib.Settings (Config.SCHEMA + ".appearance");
            var custom_path = appearance_settings.get_string ("workspace-switcher-background");
            if (custom_path != "" && FileUtils.test (custom_path, FileTest.IS_REGULAR)) {
                background_file = GLib.File.new_for_path (custom_path);
            }

            if (system_background == null) {
#if HAS_MUTTER332
                system_background = new Meta.Background (background_actor.meta_display);
#elif HAS_MUTTER330
                system_background = new Meta.Background (meta_display);
#else
                system_background = new Meta.Background (meta_screen);
#endif
                system_background.set_color (DEFAULT_BACKGROUND_COLOR);
                system_background.set_file (background_file, GDesktop.BackgroundStyle.WALLPAPER);
            }

#if HAS_MUTTER332
            background_actor.background = system_background;
#else
            background = system_background;
#endif

            var cache = Meta.BackgroundImageCache.get_default ();
            var image = cache.load (background_file);
            if (image.is_loaded ()) {
                image = null;
                Idle.add (() => {
                    loaded ();
                    return false;
                });
            } else {
                ulong handler = 0;
                handler = image.loaded.connect (() => {
                    loaded ();
                    SignalHandler.disconnect (image, handler);
                    image = null;
                });
            }
        }

        public static void refresh () {
            // Meta.Background.refresh_all does not refresh backgrounds with the WALLPAPER style.
            // (Last tested with mutter 3.28)
            // As a workaround, re-apply the current color again to force the wallpaper texture
            // to be rendered from scratch.
            if (system_background != null)
                system_background.set_color (DEFAULT_BACKGROUND_COLOR);
        }
    }
}
