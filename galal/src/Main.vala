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
    const OptionEntry[] OPTIONS = {
        { "version", 0, OptionFlags.NO_ARG, OptionArg.CALLBACK, (void*) print_version, "Print version", null },
        { null }
    };

    void print_version () {
        stdout.printf ("Gala %s\n", Config.VERSION);
        Meta.exit (Meta.ExitCode.SUCCESS);
    }

    public static int main (string[] args) {
        unowned OptionContext ctx = Meta.get_option_context ();
        ctx.add_main_entries (Gala.OPTIONS, null);
        try {
            ctx.parse (ref args);
        } catch (Error e) {
            stderr.printf ("Error initializing: %s\n", e.message);
            Meta.exit (Meta.ExitCode.ERROR);
        }

        Meta.Plugin.manager_set_plugin_type (typeof (WindowManagerGala));

        Meta.Util.set_wm_name ("Mutter(Gala)");

        /**
         * Prevent Meta.init () from causing gtk to load gail and at-bridge
         * Taken from Gnome-Shell main.c
         */
        GLib.Environment.set_variable ("NO_GAIL", "1", true);
        GLib.Environment.set_variable ("NO_AT_BRIDGE", "1", true);
        Meta.init ();
        GLib.Environment.unset_variable ("NO_GAIL");
        GLib.Environment.unset_variable ("NO_AT_BRIDGE");

        Plank.Paths.initialize ("plank", Config.DATADIR + "/plank");

        // Force initialization of static fields in Utils class
        // https://bugzilla.gnome.org/show_bug.cgi?id=543189
        typeof (Gala.Utils).class_ref ();

        return Meta.run ();
    }
}
