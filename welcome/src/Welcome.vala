/***

    Copyright (C) 2018 Enso Developers

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as
    published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses>

***/

using Gtk;
using Granite;

namespace Welcome {

public class Welcome : Gtk.Application {

    private static Welcome app;
    private WelcomeWindow window = null;
    private static bool start_launch = false;
    public static Gtk.IconTheme icon_theme { get; set; default = null; }

    public Welcome () {
        Object (application_id: "org.enso.welcome",
        flags: ApplicationFlags.FLAGS_NONE);
    }

    static const OptionEntry[] entries = {
        { "launch-start", 's', 0, OptionArg.NONE, ref start_launch, "Launch welcome screen at start up", null },
        { null }
    };

    protected override void activate () {
        // if app is already open
        if (window != null) {
            window.present ();
            return;
        }

        window = new WelcomeWindow (start_launch);
        window.set_application (this);
        window.delete_event.connect(window.main_quit);
        window.show_all ();

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("org/enso/welcome/application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (),
            provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

    		weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
    		default_theme.add_resource_path ("/org/enso/welcome/icon");
    		this.icon_theme = Gtk.IconTheme.get_default ();

    }

    public static Welcome get_instance () {
        if (app == null)
            app = new Welcome ();

        return app;
    }

    public static int main (string[] args) {

        // Init internationalization support
        Intl.setlocale (LocaleCategory.ALL, "");
        //Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");
        //Intl.textdomain (Build.GETTEXT_PACKAGE);

        app = new Welcome ();

        if (args.length > 1) {
            var context = new OptionContext ("");
            context.add_main_entries (entries, "welcome");
            context.add_group (Gtk.get_option_group (true));

            try {
                context.parse (ref args);
            } catch (Error e) {
                print (e.message + "\n");
            }
        }

        return app.run (args);
    }
}
}
