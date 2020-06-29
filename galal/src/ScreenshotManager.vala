//
//  Copyright (C) 2016 Rico Tzschichholz, Santiago León O.
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
    const string EXTENSION = ".png";
    const int UNCONCEAL_TEXT_TIMEOUT = 2000;

    [DBus (name="org.gnome.Shell.Screenshot")]
    public class ScreenshotManager : Object {
        static ScreenshotManager? instance;

        [DBus (visible = false)]
        public static unowned ScreenshotManager init (WindowManager wm) {
            if (instance == null)
                instance = new ScreenshotManager (wm);

            return instance;
        }

        WindowManager wm;
        Settings desktop_settings;

        string prev_font_regular;
        string prev_font_document;
        string prev_font_mono;
        uint conceal_timeout;

        construct {
            desktop_settings = new Settings ("org.gnome.desktop.interface");
        }

        ScreenshotManager (WindowManager _wm) {
            wm = _wm;
        }

        public void flash_area (int x, int y, int width, int height) throws DBusError, IOError {
            debug ("Flashing area");

            double[] keyframes = { 0.3f, 0.8f };
            GLib.Value[] values = { 180U, 0U };

            var transition = new Clutter.KeyframeTransition ("opacity");
            transition.duration = 200;
            transition.remove_on_complete = true;
            transition.progress_mode = Clutter.AnimationMode.LINEAR;
            transition.set_key_frames (keyframes);
            transition.set_values (values);
            transition.set_to_value (0.0f);

            var flash_actor = new Clutter.Actor ();
            flash_actor.set_size (width, height);
            flash_actor.set_position (x, y);
            flash_actor.set_background_color (Clutter.Color.get_static (Clutter.StaticColor.WHITE));
            flash_actor.set_opacity (0);
            flash_actor.transitions_completed.connect ((actor) => {
                wm.top_window_group.remove_child (actor);
                actor.destroy ();
            });

            wm.top_window_group.add_child (flash_actor);
            flash_actor.add_transition ("flash", transition);
        }

        public async void screenshot (bool include_cursor, bool flash, string filename, out bool success, out string filename_used) throws DBusError, IOError {
            debug ("Taking screenshot");

            int width, height;
#if HAS_MUTTER330
            wm.get_display ().get_size (out width, out height);
#else
            wm.get_screen ().get_size (out width, out height);
#endif

            var image = take_screenshot (0, 0, width, height, include_cursor);
            unconceal_text ();

            if (flash) {
                flash_area (0, 0, width, height);
            }

            success = yield save_image (image, filename, out filename_used);
        }

        public async void screenshot_area (int x, int y, int width, int height, bool flash, string filename, out bool success, out string filename_used) throws DBusError, IOError {
            yield screenshot_area_with_cursor (x, y, width, height, false, flash, filename, out success, out filename_used);
        }

        public async void screenshot_area_with_cursor (int x, int y, int width, int height, bool include_cursor, bool flash, string filename, out bool success, out string filename_used) throws DBusError, IOError {
            debug ("Taking area screenshot");

            yield wait_stage_repaint ();

            var image = take_screenshot (x, y, width, height, include_cursor);
            unconceal_text ();

            if (flash) {
                flash_area (x, y, width, height);
            }

            success = yield save_image (image, filename, out filename_used);
            if (!success)
                throw new DBusError.FAILED ("Failed to save image");
        }

        public async void screenshot_window (bool include_frame, bool include_cursor, bool flash, string filename, out bool success, out string filename_used) throws DBusError, IOError {
            debug ("Taking window screenshot");

#if HAS_MUTTER330
            var window = wm.get_display ().get_focus_window ();
#else
            var window = wm.get_screen ().get_display ().get_focus_window ();
#endif

            if (window == null) {
                unconceal_text ();
                throw new DBusError.FAILED ("Cannot find active window");
            }

            var window_actor = (Meta.WindowActor) window.get_compositor_private ();
            unowned Meta.ShapedTexture window_texture = (Meta.ShapedTexture) window_actor.get_texture ();

            float actor_x, actor_y;
            window_actor.get_position (out actor_x, out actor_y);

            var rect = window.get_frame_rect ();
            if (include_frame) {
                rect = window.frame_rect_to_client_rect (rect);
            }

            Cairo.RectangleInt clip = { rect.x - (int) actor_x, rect.y - (int) actor_y, rect.width, rect.height };
            var image = (Cairo.ImageSurface) window_texture.get_image (clip);
            if (include_cursor) {
                image = composite_stage_cursor (image, { rect.x, rect.y, rect.width, rect.height });
            }

            unconceal_text ();

            if (flash) {
                flash_area (rect.x, rect.y, rect.width, rect.height);
            }

            success = yield save_image (image, filename, out filename_used);
        }

        public async void select_area (out int x, out int y, out int width, out int height) throws DBusError, IOError {
            var selection_area = new SelectionArea (wm);
            selection_area.closed.connect (() => Idle.add (select_area.callback));
            wm.ui_group.add (selection_area);
            selection_area.start_selection ();

            yield;
            selection_area.destroy ();

            if (selection_area.cancelled) {
                throw new GLib.IOError.CANCELLED ("Operation was cancelled");
            }

            yield wait_stage_repaint ();
            selection_area.get_selection_rectangle (out x, out y, out width, out height);
        }

        private void unconceal_text () {
            if (conceal_timeout == 0) {
                return;
            }

            desktop_settings.set_string ("font-name", prev_font_regular);
            desktop_settings.set_string ("monospace-font-name", prev_font_mono);
            desktop_settings.set_string ("document-font-name", prev_font_document);

            Source.remove (conceal_timeout);
            conceal_timeout = 0;
        }

        public async void conceal_text () throws DBusError, IOError {
            if (conceal_timeout > 0) {
                Source.remove (conceal_timeout);
            } else {
                prev_font_regular = desktop_settings.get_string ("font-name");
                prev_font_mono = desktop_settings.get_string ("monospace-font-name");
                prev_font_document = desktop_settings.get_string ("document-font-name");

                desktop_settings.set_string ("font-name", "Redacted Script Regular 9");
                desktop_settings.set_string ("monospace-font-name", "Redacted Script Light 10");
                desktop_settings.set_string ("document-font-name", "Redacted Script Regular 10");
            }

            conceal_timeout = Timeout.add (UNCONCEAL_TEXT_TIMEOUT, () => {
                unconceal_text ();
                return Source.REMOVE;
            });
        }

        public async GLib.HashTable<string, Variant> pick_color () throws DBusError, IOError {
            var pixel_picker = new PixelPicker (wm);
            pixel_picker.closed.connect (() => Idle.add (pick_color.callback));
            wm.ui_group.add (pixel_picker);
            pixel_picker.start_selection ();

            yield;
            pixel_picker.destroy ();

            if (pixel_picker.cancelled) {
                throw new GLib.IOError.CANCELLED ("Operation was cancelled");
            }

            int x = 0, y = 0;
            pixel_picker.get_point (out x, out y);

            var image = take_screenshot (x, y, 1, 1, false);

            assert (image.get_format () == Cairo.Format.ARGB32);

            unowned uchar[] data = image.get_data ();

            double r, g, b;
            if (GLib.ByteOrder.HOST == GLib.ByteOrder.LITTLE_ENDIAN) {
                r = data[2] / 255.0f;
                g = data[1] / 255.0f;
                b = data[0] / 255.0f;
            } else {
                r = data[1] / 255.0f;
                g = data[2] / 255.0f;
                b = data[3] / 255.0f;
            }

            var result = new GLib.HashTable<string, Variant> (str_hash, str_equal);
            result.insert ("color", new GLib.Variant ("(ddd)", r, g, b));

            return result;
        }

        static string find_target_path () {
            // Try to create dedicated "Screenshots" subfolder in PICTURES xdg-dir
            unowned string? base_path = Environment.get_user_special_dir (UserDirectory.PICTURES);
            if (base_path != null && FileUtils.test (base_path, FileTest.EXISTS)) {
                var path = Path.build_path (Path.DIR_SEPARATOR_S, base_path, _("Screenshots"));
                if (FileUtils.test (path, FileTest.EXISTS)) {
                    return path;
                } else if (DirUtils.create (path, 0755) == 0) {
                    return path;
                } else {
                    return base_path;
                }
            }

            return Environment.get_home_dir ();
        }

        static async bool save_image (Cairo.ImageSurface image, string filename, out string used_filename) {
            used_filename = filename;

            // We only alter non absolute filename because absolute
            // filename is used for temp clipboard file and shouldn't be changed
            if (!Path.is_absolute (used_filename)) {
                if (!used_filename.has_suffix (EXTENSION)) {
                    used_filename = used_filename.concat (EXTENSION);
                }

                var scale_factor = InternalUtils.get_ui_scaling_factor ();
                if (scale_factor > 1) {
                    var scale_pos = -EXTENSION.length;
                    used_filename = used_filename.splice (scale_pos, scale_pos, "@%ix".printf (scale_factor));
                }

                var path = find_target_path ();
                used_filename = Path.build_filename (path, used_filename, null);
            }

            try {
                var screenshot = Gdk.pixbuf_get_from_surface (image, 0, 0, image.get_width (), image.get_height ());
                var file = File.new_for_path (used_filename);
                FileIOStream stream;
                if (file.query_exists ()) {
                    stream = yield file.open_readwrite_async (FileCreateFlags.NONE);
                } else {
                    stream = yield file.create_readwrite_async (FileCreateFlags.NONE);
                }
                yield screenshot.save_to_stream_async (stream.output_stream, "png");
                return true;
            } catch (GLib.Error e) {
                warning ("could not save file: %s", e.message);
                return false;
            }
        }

        Cairo.ImageSurface take_screenshot (int x, int y, int width, int height, bool include_cursor) {
            Cairo.ImageSurface image;
            Clutter.Capture[] captures;
            wm.stage.capture (false, {x, y, width, height}, out captures);

            if (captures.length == 0)
                image = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height);
            else if (captures.length == 1)
                image = captures[0].image;
            else
                image = composite_capture_images (captures, x, y, width, height);

            if (include_cursor) {
                image = composite_stage_cursor (image, { x, y, width, height});
            }

            image.mark_dirty ();
            return image;
        }

        Cairo.ImageSurface composite_capture_images (Clutter.Capture[] captures, int x, int y, int width, int height) {
            var image = new Cairo.ImageSurface (captures[0].image.get_format (), width, height);
            var cr = new Cairo.Context (image);

            foreach (unowned Clutter.Capture capture in captures) {
                // Ignore capture regions with scale other than 1 for now; mutter can't
                // produce them yet, so there is no way to test them.
                double capture_scale = 1.0;
                capture.image.get_device_scale (out capture_scale, null);
                if (capture_scale != 1.0)
                    continue;

                cr.save ();
                cr.translate (capture.rect.x - x, capture.rect.y - y);
                cr.set_source_surface (capture.image, 0, 0);
                cr.restore ();
            }

            return image;
        }

        Cairo.ImageSurface composite_stage_cursor (Cairo.ImageSurface image, Cairo.RectangleInt image_rect) {
#if HAS_MUTTER330
            unowned Meta.CursorTracker cursor_tracker = wm.get_display ().get_cursor_tracker ();
#else
            unowned Meta.CursorTracker cursor_tracker = wm.get_screen ().get_cursor_tracker ();
#endif

            int x, y;
            cursor_tracker.get_pointer (out x, out y, null);

            var region = new Cairo.Region.rectangle (image_rect);
            if (!region.contains_point (x, y)) {
                return image;
            }

            unowned Cogl.Texture texture = cursor_tracker.get_sprite ();
            if (texture == null) {
                return image;
            }

            int width = (int)texture.get_width ();
            int height = (int)texture.get_height ();

            uint8[] data = new uint8[width * height * 4];
            texture.get_data (Cogl.PixelFormat.RGBA_8888, 0, data);

            var cursor_image = new Cairo.ImageSurface.for_data (data, Cairo.Format.ARGB32, width, height, width * 4);
            var target = new Cairo.ImageSurface (Cairo.Format.ARGB32, image_rect.width, image_rect.height);

            var cr = new Cairo.Context (target);
            cr.set_operator (Cairo.Operator.OVER);
            cr.set_source_surface (image, 0, 0);
            cr.paint ();

            cr.set_operator (Cairo.Operator.OVER);
            cr.set_source_surface (cursor_image, x - image_rect.x, y - image_rect.y);
            cr.paint ();

            return (Cairo.ImageSurface)cr.get_target ();
        }

        async void wait_stage_repaint () {
            ulong signal_id = 0UL;
            signal_id = wm.stage.paint.connect_after (() => {
                wm.stage.disconnect (signal_id);
                Idle.add (wait_stage_repaint.callback);
            });

            wm.stage.queue_redraw ();
            yield;
        }
    }
}
