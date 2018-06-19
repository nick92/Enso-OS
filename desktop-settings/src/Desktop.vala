/*
* Copyright (c) 2011-2017 elementary LLC. (http://launchpad.net/switchboard-plug-pantheon-shell)
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
* Authored by: Tom Beckmann
*/

public class GalaPlug : Gtk.Application {

    Gtk.Stack stack;
    DesktopWindow window = null;
    static GalaPlug app;
    string display_name = "Desktop";

    public GalaPlug () {
        Object (application_id: "com.enso.plug.desktop",
        flags: ApplicationFlags.FLAGS_NONE);
        /*var settings = new Gee.TreeMap<string, string?> (null, null);
        settings.set ("desktop", null);
        settings.set ("desktop/wallpaper", "wallpaper");
        settings.set ("desktop/dock", "dock");
        settings.set ("desktop/hot-corners", "hotc");
        /*Object (category: Category.PERSONAL,
                code_name: "pantheon-desktop",
                display_name: _("Desktop"),
                description: _("Configure the dock, hot corners, and change wallpaper"),
                icon: "preferences-desktop-wallpaper",
                supported_settings: settings);*/
    }

    public static int main (string[] args) {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Build.GETTEXT_PACKAGE);

        app = new GalaPlug ();

        if (args[1] == "-s") {
            return 0;
        }

        return app.run (args);
    }

    protected override void activate () {
        if (window != null) {
            window.present ();
            return;
        }

        window = new DesktopWindow ();
        window.set_application (this);
        window.delete_event.connect(window.main_quit);
        window.show_all ();

    }
}
