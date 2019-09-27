/*
* Copyright (c) 2011-2017 elementary LLC. (http://launchpad.net/pantheon-greeter)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
*/

public class Wallpaper : Gtk.Stack {
    List<Gtk.Image> wallpapers = new List<Gtk.Image> ();
    List<Cancellable> loading_wallpapers = new List<Cancellable> ();
    Queue<Gtk.Image> unused_wallpapers = new Queue<Gtk.Image> ();

    int gpu_limit;

    string[] cache_path = {};
    Gdk.Pixbuf[] cache_pixbuf = {};
    int max_cache = 3;

    string last_loaded = "";

    public Gdk.Pixbuf? background_pixbuf;
    public int screen_width { get; set; }
    public int screen_height { get; set; }

    public Wallpaper () {
        Object (transition_type: Gtk.StackTransitionType.CROSSFADE);
    }

    construct {
        GL.GLint result = 1;
        GL.glGetIntegerv(GL.GL_MAX_TEXTURE_SIZE, out result);
        gpu_limit = result;
    }

    string get_default () {
        var settings = new KeyFile ();
        string default_wallpaper="";
        try {
            settings.load_from_file (Constants.CONF_DIR + "/pantheon-greeter.conf", KeyFileFlags.KEEP_COMMENTS);
            default_wallpaper = settings.get_string ("greeter", "default-wallpaper");
        } catch (Error e) {
            warning (e.message);
        }
        return default_wallpaper;
    }

    public void reposition () {
        set_wallpaper (last_loaded);
    }

    public void set_wallpaper (string? path) {
        var file_path = (path == null || path == "") ? get_default () : path;

        var file = File.new_for_path (file_path);

        if (!file.query_exists ()) {
            warning ("File %s does not exist!\n", file_path);
            return;
        }

        last_loaded = file_path;

        clean_cache ();
        load_wallpaper.begin (file_path, file);
    }

    async void load_wallpaper (string path, File file) {

        try {
            Gdk.Pixbuf? buf = try_load_from_cache (path);
            //if we still dont have a wallpaper now, load from file
            if (buf == null) {
                var cancelable = new Cancellable ();
                loading_wallpapers.append (cancelable);
                InputStream stream = yield file.read_async (GLib.Priority.DEFAULT);
                buf = yield new Gdk.Pixbuf.from_stream_async (stream, cancelable);
                loading_wallpapers.remove (cancelable);
                //add loaded wallpapers and paths to cache
                cache_path += path;
                cache_pixbuf += buf;
                background_pixbuf = buf;
                // we downscale the pixbuf as far as we can on the CPU
                buf = validate_pixbuf (buf);
            } else {
                buf = validate_pixbuf (buf);
            }

            // check if the currently loaded wallpaper is the one we loaded in this method
            if (last_loaded != path) {
                return; //if not, abort
            }

            var new_wallpaper = make_image ();
            new_wallpaper.pixbuf = buf;
            //get_style_context ().add_class ("background");
            add (new_wallpaper);
            show_all ();
            visible_child = new_wallpaper;

            // abort all currently loading wallpapers
            foreach (var c in loading_wallpapers) {
                c.cancel ();
            }

            foreach (var other_wallpaper in wallpapers) {
                wallpapers.remove (other_wallpaper);

                Timeout.add (transition_duration, () => {
                    remove (other_wallpaper);
                    unused_wallpapers.push_tail (other_wallpaper);
                    return false;
                });
            }
            wallpapers.append (new_wallpaper);

        } catch (IOError.CANCELLED e) {
            warning (@"Cancelled to load '$path'");
            // do nothing, we cancelled on purpose
        } catch (Error e) {
            //  if (get_default() != path) {
            //      set_wallpaper (get_default ());
            //  }
            warning (@"Can't load: '$path' due to $(e.message)");
        }
    }

    /**
     * Creates a texture. It also recycles old unused wallpapers if possible
     * as spamming constructors is expensive.
     */
    Gtk.Image make_image () {
        if (unused_wallpapers.is_empty ()) {
            return new Gtk.Image ();
        } else {
            return unused_wallpapers.pop_head ();
        }
    }

    /**
     * Resizes the cache if there are more pixbufs cached then max_mache allows
     */
    void clean_cache () {
        int l = cache_path.length;
        if (l > max_cache) {
            cache_path = cache_path [l - max_cache : l];
            cache_pixbuf = cache_pixbuf [l - max_cache : l];
        }
    }

    /**
     * Looks up the pixbuf of the image-file with the given path in the cache.
     * Returns null if there is no pixbuf for that file in cache
     */
    Gdk.Pixbuf? try_load_from_cache (string path) {
        for (int i = 0; i < cache_path.length; i++) {
            if (cache_path[i] == path)
                return cache_pixbuf[i];
        }
        return null;
    }

    /**
     * makes the pixbuf fit inside the GPU limit and scales it to
     * screen size to save memory.
     */
    Gdk.Pixbuf validate_pixbuf (Gdk.Pixbuf pixbuf) {
        return scale_to_rect (pixbuf, screen_width, screen_height);
    }

    public static Gdk.Pixbuf scale_to_rect (Gdk.Pixbuf pixbuf, int rect_width, int rect_height) {
        if (pixbuf.width == rect_width && pixbuf.height == rect_height) {
            return pixbuf;
        }
        double target_aspect = (double) rect_width / rect_height;
        double aspect = (double) pixbuf.width / pixbuf.height;
        double scale, offset_x = 0, offset_y = 0;
        if (aspect > target_aspect) {
            scale = (double) rect_height / pixbuf.height;
            offset_x = (pixbuf.width * scale - rect_width) / 2;
        } else {
            scale = (double) rect_width / pixbuf.width;
            offset_y = (pixbuf.height * scale - rect_height) / 2;
        }

        var scaled_pixbuf = new Gdk.Pixbuf (pixbuf.colorspace, pixbuf.has_alpha, pixbuf.bits_per_sample, rect_width, rect_height);
        pixbuf.scale (scaled_pixbuf, 0, 0, rect_width, rect_height, -offset_x, -offset_y, scale, scale, Gdk.InterpType.BILINEAR);

        return scaled_pixbuf;
    }
}
