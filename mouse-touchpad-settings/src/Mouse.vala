/*
 * Copyright (c) 2011-2018 elementary, Inc. (https://elementary.io)
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
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 */

public class MouseTouchpad.Plug : Gtk.Application {
    
    private Gtk.Stack stack;
    private PlugWindow window = null;
    private static Plug app;
    private string display_name = "Mouse & Touchpad";

    public Plug () {
        Object (
            application_id: "com.enso.plug.mouse-touchpad",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        if (window != null) {
            window.present ();
            return;
        }

        window = new PlugWindow ();
        window.set_application (this);
        window.delete_event.connect(window.main_quit);
        window.show_all ();

    }

    public static int main (string[] args) {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Build.GETTEXT_PACKAGE);

        app = new Plug ();

        if (args[1] == "-s") {
            return 0;
        }

        return app.run (args);
    }

    public void search_callback (string location) {
        switch (location) {
            case "mouse":
                stack.set_visible_child_name ("mouse");
                break;
            case "touchpad":
                stack.set_visible_child_name ("touchpad");
                break;
            case "general":
            default:
                stack.set_visible_child_name ("general");
                break;
        }
    }

    /* 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior") */
    public async Gee.TreeMap<string, string> search (string search) {
        var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
        search_results.set ("%s → %s".printf (display_name, _("Primary button")), "general");
        search_results.set ("%s → %s".printf (display_name, _("Reveal pointer")), "general");
        search_results.set ("%s → %s".printf (display_name, _("Long-press secondary click")), "general");
        search_results.set ("%s → %s".printf (display_name, _("Long-press length")), "general");
        search_results.set ("%s → %s".printf (display_name, _("Middle click paste")), "general");
        search_results.set ("%s → %s".printf (display_name, _("Control pointer using keypad")), "general");
        search_results.set ("%s → %s".printf (display_name, _("Keypad pointer speed")), "general");
        search_results.set ("%s → %s".printf (display_name, _("Mouse")), "mouse");
        search_results.set ("%s → %s → %s".printf (display_name, _("Mouse"), _("Pointer speed")), "mouse");
        search_results.set ("%s → %s → %s".printf (display_name, _("Mouse"), _("Pointer acceleration")), "mouse");
        search_results.set ("%s → %s → %s".printf (display_name, _("Mouse"), _("Natural scrolling")), "mouse");
        search_results.set ("%s → %s".printf (display_name, _("Touchpad")), "touchpad");
        search_results.set ("%s → %s → %s".printf (display_name, _("Touchpad"), _("Pointer speed")), "touchpad");
        search_results.set ("%s → %s → %s".printf (display_name, _("Touchpad"), _("Tap to click")), "touchpad");
        search_results.set ("%s → %s → %s".printf (display_name, _("Touchpad"), _("Physical clicking")), "touchpad");
        search_results.set ("%s → %s → %s".printf (display_name, _("Touchpad"), _("Scrolling")), "touchpad");
        search_results.set ("%s → %s → %s".printf (display_name, _("Touchpad"), _("Natural scrolling")), "touchpad");
        search_results.set ("%s → %s → %s".printf (display_name, _("Touchpad"), _("Ignore while typing")), "touchpad");
        search_results.set ("%s → %s → %s".printf (display_name, _("Touchpad"), _("Ignore when mouse is connected")), "touchpad");
        return search_results;
    }
}

//  public Switchboard.Plug get_plug (Module module) {
//      debug ("Activating Mouse-Touchpad plug");

//      var plug = new MouseTouchpad.Plug ();

//      return plug;
//  }

