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

using Clutter;
using Meta;

namespace Gala.Plugins.Notify {
    public class Main : Gala.Plugin {
        private GLib.Settings behavior_settings;
        Gala.WindowManager? wm = null;

        public override void initialize (Gala.WindowManager wm) {
            behavior_settings = new GLib.Settings ("org.pantheon.desktop.gala.behavior");

            this.wm = wm;
            enable ();
        }

        void enable ()
        {
            var css_provider = new Gtk.CssProvider ();
            css_provider.load_from_resource ("/io/elementary/desktop/gala/notification.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            var server = new NotifyServer ();

            Bus.own_name (BusType.SESSION, "org.freedesktop.Notifications", BusNameOwnerFlags.NONE, (connection) => {
                try {
                    connection.register_object ("/org/freedesktop/Notifications", server);
                } catch (Error e) {
                    warning ("Registring notification server failed: %s", e.message);
                    destroy ();
                }
            },
            () => {},
            (con, name) => {
                warning ("Could not aquire bus %s", name);
                destroy ();
            });
        }

        public override void destroy () {
            if (wm == null)
                return;
        }
    }
}

public Gala.PluginInfo register_plugin () {
    return Gala.PluginInfo () {
        name = "Notify",
        author = "Gala Developers",
        plugin_type = typeof (Gala.Plugins.Notify.Main),
        provides = Gala.PluginFunction.ADDITION,
        load_priority = Gala.LoadPriority.IMMEDIATE
    };
}
