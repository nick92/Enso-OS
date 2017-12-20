/*
* Copyright (c) 2013-2014 Foto Developers (http://launchpad.net/foto)
*               2015 Erasmo Marín
*               2017 elementary LLC. (http://launchpad.net/switchboard-plug-pantheon-shell)
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
*/

public class Cache {

    static string cache_folder;
    static Gee.HashMap<string, Gdk.Pixbuf> images;

    /*
     * Static init of parameters
     */
    public static void init () {
        images = new Gee.HashMap<string, Gdk.Pixbuf> ();

        cache_folder = Path.build_path (Path.DIR_SEPARATOR_S, Environment.get_user_cache_dir (), "io.elementary.switchboard.plug.pantheon-shell");
        create_cache_path (cache_folder);
    }

    /*
     *create a new cache file for the original image path
     */
    public static bool cache_image (string uri, int width, int height, int scale) {
        try {
            var pixbuf = new Gdk.Pixbuf.from_file_at_scale (uri, width, height, true);
            string key = compute_key (uri, scale);
            string path = Path.build_filename (get_cache_path (scale), key);
            debug ("Image cached: %s", path);
            pixbuf.save (path, "png");
            images.set (key, pixbuf);
        } catch (GLib.Error err) {
            warning("cache_image failed");
            return false;
        }
        return true;
    }

    /*
     *create a new cache file for the image pixbuf at the same size
     */
    public static bool cache_image_pixbuf (Gdk.Pixbuf pixbuf, string uri, int scale) {
        try {
            string key = compute_key (uri, scale);
            pixbuf.save (Path.build_filename (get_cache_path (scale), key), "png");
            images.set (key, pixbuf);
        } catch (GLib.Error err) {
            print(err.message);
            warning("cache_image_pixbuf failed");
            return false;
        }
        return true;
    }


    /*
     *Determine if a image is cached
     */
    public static bool is_cached (string uri, int scale) {
        File file = File.new_for_path (Path.build_filename (get_cache_path (scale), compute_key (uri, scale)));
        if (!file.query_exists ())
            return false;
        return true;
    }

    /*
     *returns the cached thumbnail
     */
    public static Gdk.Pixbuf? get_cached_image (string uri, int scale) {
        string computed_key = compute_key (uri, scale);
        if (images.has_key(computed_key))
            return images.get(computed_key);

        Gdk.Pixbuf pixbuf = null;
        try {
            pixbuf = new Gdk.Pixbuf.from_file (Path.build_filename (get_cache_path (scale), computed_key));
        } catch (GLib.Error err) {
            warning("get_cached_image failed");
            return null;
        }
        images.set(computed_key, pixbuf);
        return pixbuf;
    }

    public static void clear () {
        images.clear ();
    }

    private static void create_cache_path (string cache_path) {
        var dir = GLib.File.new_for_path (cache_path);

        if (!dir.query_exists (null)) {
            try {
                dir.make_directory_with_parents (null);
                GLib.debug ("Directory '%s' created", dir.get_path ());
            } catch (Error e) {
                GLib.error ("Could not create caching directory.");
            }
        }
    }

    /*
     * Compute the key from the uri and the modification date in this format:
     * [uri key]_[mod_key]
     */
    private static string compute_key (string uri, int scale) {
        string key = compute_key_uri (uri) + "_" + compute_key_mod (uri) + scale.to_string ();
        return key;
    }

    /*
     *compute a key with the uri
     */
    private static string compute_key_uri (string uri) {
        string key_uri = GLib.Checksum.compute_for_string (ChecksumType.MD5, uri);
        return key_uri;
    }

    /*
     *compute a key with the modification date
     */
    private static string compute_key_mod (string uri) {
        GLib.File file = GLib.File.new_for_uri (uri);
        string key_mod = "";

        try {
            FileInfo info = file.query_info (GLib.FileAttribute.TIME_MODIFIED, 0);
            key_mod = GLib.Checksum.compute_for_string (GLib.ChecksumType.MD5, info.get_modification_time ().tv_sec.to_string ());
        } catch (Error e) {
            critical ("Failed to get modification date: %s", e.message);
        }

        return key_mod;
    }

    private static string get_cache_path (int scale) {
        var cache_scale_folder = Path.build_path (Path.DIR_SEPARATOR_S, cache_folder, scale.to_string ());
        create_cache_path (cache_scale_folder);
        return cache_scale_folder;
    }
}
