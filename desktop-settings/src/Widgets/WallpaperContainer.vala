/*-
 * Copyright (c) 2015-2017 elementary LLC. (https://bugs.launchpad.net/switchboard-plug-pantheon-shell)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Erasmo Marín
 *
 */

public class WallpaperContainer : Gtk.FlowBoxChild {
    private Gtk.Revealer check_revealer;
    private Gtk.Image image;

    public string uri { get; construct; }
    public Gdk.Pixbuf thumb { get; construct; }

    const string CARD_STYLE_CSS = """
        flowboxchild,
        GtkFlowBox .grid-child {
            background-color: transparent;
        }

        flowboxchild:focus .card,
        GtkFlowBox .grid-child:focus .card {
            border: 3px solid alpha (#000, 0.2);
            border-radius: 3px;
        }

        flowboxchild:focus .card:checked,
        GtkFlowBox .grid-child:focus .card:checked {
            border-color: @selected_bg_color;
        }
    """;

    public bool checked {
        get {
            return Gtk.StateFlags.CHECKED in get_state_flags ();
        } set {
            if (value) {
                image.set_state_flags (Gtk.StateFlags.CHECKED, false);
                check_revealer.reveal_child = true;
            } else {
                image.unset_state_flags (Gtk.StateFlags.CHECKED);
                check_revealer.reveal_child = false;
            }

            queue_draw ();
        }
    }

    public bool selected {
        get {
            return Gtk.StateFlags.SELECTED in get_state_flags ();
        } set {
            if (value) {
                set_state_flags (Gtk.StateFlags.SELECTED, false);
            } else {
                unset_state_flags (Gtk.StateFlags.SELECTED);
            }

            queue_draw ();
        }
    }

    public WallpaperContainer (string uri) {
        Object (uri: uri);
    }

    construct {
        var scale = get_style_context ().get_scale ();
        var provider = new Gtk.CssProvider ();
        try {
            provider.load_from_data (CARD_STYLE_CSS, CARD_STYLE_CSS.length);
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            critical (e.message);
        }

         try {
            if (uri != null) {
                if (Cache.is_cached (uri, scale)) {
                    thumb = Cache.get_cached_image (uri, scale);
                } else {
                    thumb = new Gdk.Pixbuf.from_file_at_scale (GLib.Filename.from_uri (uri), 162 * scale, 100 * scale, false);
                    Cache.cache_image_pixbuf (thumb, uri, scale);
                }
            } else {
                thumb = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, 162 * scale, 100 * scale);
            }
        } catch (Error e) {
            critical ("Failed to load wallpaper thumbnail: %s", e.message);
            return;
        }

        image = new Gtk.Image ();
        image.gicon = thumb;
        image.halign = Gtk.Align.CENTER;
        image.valign = Gtk.Align.CENTER;
        image.get_style_context ().set_scale (1);
        // We need an extra grid to not apply a scale == 1 to the "card" style.
        var card_box = new Gtk.Grid ();
        card_box.get_style_context ().add_class ("card");
        card_box.add (image);
        card_box.margin = 9;

        var check = new Gtk.Image.from_resource ("/org/enso/desktop/checked.svg");
        check.halign = Gtk.Align.START;
        check.valign = Gtk.Align.START;

        check_revealer = new Gtk.Revealer ();
        check_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        check_revealer.add (check);

        var overlay = new Gtk.Overlay ();
        overlay.add (card_box);
        overlay.add_overlay (check_revealer);

        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        height_request = thumb.get_height () / scale + 18;
        width_request = thumb.get_width () / scale + 18;
        margin = 6;
        add (overlay);

        activate.connect (() => {
            checked = true;
        });
    }
}
