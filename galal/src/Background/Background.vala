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
    public class Background : Object {
        const double ANIMATION_OPACITY_STEP_INCREMENT = 4.0;
        const double ANIMATION_MIN_WAKEUP_INTERVAL = 1.0;

        public signal void changed ();
        public signal void loaded ();

#if HAS_MUTTER330
        public Meta.Display display { get; construct; }
#else
        public Meta.Screen screen { get; construct; }
#endif
        public int monitor_index { get; construct; }
        public BackgroundSource background_source { get; construct; }
        public bool is_loaded { get; private set; default = false; }
        public GDesktop.BackgroundStyle style { get; construct; }
        public string? filename { get; construct; }
        public Meta.Background background { get; private set; }

        Animation? animation = null;
        Gee.HashMap<string,ulong> file_watches;
        Cancellable cancellable;
        uint update_animation_timeout_id = 0;

#if HAS_MUTTER330
        public Background (Meta.Display display, int monitor_index, string? filename,
                BackgroundSource background_source, GDesktop.BackgroundStyle style) {
            Object (display: display,
                    monitor_index: monitor_index,
                    background_source: background_source,
                    style: style,
                    filename: filename);
        }
#else
        public Background (Meta.Screen screen, int monitor_index, string? filename,
                BackgroundSource background_source, GDesktop.BackgroundStyle style) {
            Object (screen: screen,
                    monitor_index: monitor_index,
                    background_source: background_source,
                    style: style,
                    filename: filename);
        }
#endif

        construct {
#if HAS_MUTTER330
            background = new Meta.Background (display);
#else
            background = new Meta.Background (screen);
#endif
            background.set_data<unowned Background> ("delegate", this);

            file_watches = new Gee.HashMap<string,ulong> ();
            cancellable = new Cancellable ();

            background_source.changed.connect (settings_changed);

            load ();
        }

        public void destroy () {
            cancellable.cancel ();
            remove_animation_timeout ();

            var cache = BackgroundCache.get_default ();

            foreach (var watch in file_watches.values) {
                SignalHandler.disconnect (cache, watch);
            }

            background_source.changed.disconnect (settings_changed);
        }

        public void update_resolution () {
            if (animation != null) {
                remove_animation_timeout ();
                update_animation ();
            }
        }

        void set_loaded () {
            if (is_loaded)
                return;

            is_loaded = true;

            Idle.add (() => {
                loaded ();
                return false;
            });
        }

        void load_pattern () {
            string color_string;
            var settings = background_source.settings;

            color_string = settings.get_string ("primary-color");
            var color = Clutter.Color.from_string (color_string);

            color_string = settings.get_string ("secondary-color");
            var second_color = Clutter.Color.from_string (color_string);

            var shading_type = settings.get_enum ("color-shading-type");

            if (shading_type == GDesktop.BackgroundShading.SOLID)
                background.set_color (color);
            else
                background.set_gradient ((GDesktop.BackgroundShading) shading_type, color, second_color);
        }

        void watch_file (string filename) {
            if (file_watches.has_key (filename))
                return;

            var cache = BackgroundCache.get_default ();

            cache.monitor_file (filename);

            file_watches[filename] = cache.file_changed.connect ((changed_file) => {
                if (changed_file == filename) {
                    var image_cache = Meta.BackgroundImageCache.get_default ();
                    image_cache.purge (File.new_for_path (changed_file));
                    changed ();
                }
            });
        }

        void remove_animation_timeout () {
            if (update_animation_timeout_id != 0) {
                Source.remove (update_animation_timeout_id);
                update_animation_timeout_id = 0;
            }
        }

        void update_animation () {
            update_animation_timeout_id = 0;

#if HAS_MUTTER330
            animation.update (display.get_monitor_geometry (monitor_index));
#else
            animation.update (screen.get_monitor_geometry (monitor_index));
#endif
            var files = animation.key_frame_files;

            Clutter.Callback finish = () => {
                set_loaded ();

                if (files.length > 1)
                    background.set_blend (File.new_for_path (files[0]), File.new_for_path (files[1]), animation.transition_progress, style);
                else if (files.length > 0)
                    background.set_file (File.new_for_path (files[0]), style);
                else
                    background.set_file (null, style);

                queue_update_animation ();
            };

            var cache = Meta.BackgroundImageCache.get_default ();
            var num_pending_images = files.length;
            for (var i = 0; i < files.length; i++) {
                watch_file (files[i]);

                var image = cache.load (File.new_for_path (files[i]));

                if (image.is_loaded ()) {
                    num_pending_images--;
                    if (num_pending_images == 0)
                        finish (null);
                } else {
                    ulong handler = 0;
                    handler = image.loaded.connect (() => {
                        SignalHandler.disconnect (image, handler);
                        if (--num_pending_images == 0)
                            finish (null);
                    });
                }
            }
        }

        void queue_update_animation () {
            if (update_animation_timeout_id != 0)
                return;

            if (cancellable == null || cancellable.is_cancelled ())
                return;

            if (animation.transition_duration == 0)
                return;

            var n_steps = 255.0 / ANIMATION_OPACITY_STEP_INCREMENT;
            var time_per_step = (animation.transition_duration * 1000) / n_steps;

            var interval = (uint32) Math.fmax (ANIMATION_MIN_WAKEUP_INTERVAL * 1000, time_per_step);

            if (interval > uint32.MAX)
                return;

            update_animation_timeout_id = Timeout.add (interval, () => {
                update_animation_timeout_id = 0;
                update_animation ();
                return false;
            });
        }

        async void load_animation (string filename) {
            animation = yield BackgroundCache.get_default ().get_animation (filename);

            if (animation == null || cancellable.is_cancelled ()) {
                set_loaded ();
                return;
            }

            update_animation ();
            watch_file (filename);
        }

        void load_image (string filename) {
            background.set_file (File.new_for_path (filename), style);
            watch_file (filename);

            var cache = Meta.BackgroundImageCache.get_default ();
            var image = cache.load (File.new_for_path (filename));
            if (image.is_loaded ())
                set_loaded ();
            else {
                ulong handler = 0;
                handler = image.loaded.connect (() => {
                    set_loaded ();
                    SignalHandler.disconnect (image, handler);
                });
            }
        }

        void load_file (string filename) {
            if (filename.has_suffix (".xml"))
                load_animation.begin (filename);
            else
                load_image (filename);
        }

        void load () {
            load_pattern ();

            if (filename == null)
                set_loaded ();
            else
                load_file (filename);
        }

        void settings_changed () {
            changed ();
        }
    }
}
