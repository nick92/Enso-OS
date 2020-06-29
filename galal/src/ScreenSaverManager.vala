//
//  Copyright 2020 elementary, Inc. (https://elementary.io)
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
    [DBus (name="org.freedesktop.ScreenSaver")]
    public class ScreenSaverManager : Object {
        public signal void active_changed (bool new_value);

        [DBus (visible = false)]
        public GNOMEScreenSaverManager gnome_manager { get; construct; }

        [DBus (visible = false)]
        public ScreenShield screen_shield { get; construct; }

        public ScreenSaverManager (ScreenShield shield) {
            Object (screen_shield: shield);
        }

        construct {
            gnome_manager = new GNOMEScreenSaverManager (this);
            screen_shield.active_changed.connect (() => {
                active_changed (screen_shield.active);
                gnome_manager.active_changed (screen_shield.active);
            });
        }

        public void @lock () throws GLib.Error {
            screen_shield.@lock (true);
        }

        public bool get_active () throws GLib.Error {
            return screen_shield.active;
        }

        public void set_active (bool active) throws GLib.Error {
            if (active) {
                screen_shield.activate (true);
            } else {
                screen_shield.deactivate (false);
            }
        }

        public uint get_active_time () throws GLib.Error {
            var started = screen_shield.activation_time;
            if (started > 0) {
                return (uint)Math.floor ((GLib.get_monotonic_time () - started) / 1000000);
            } else {
                return 0;
            }
        }
    }

    [DBus (name="org.gnome.ScreenSaver")]
    public class GNOMEScreenSaverManager : GLib.Object {
        [DBus (visible = false)]
        public weak ScreenSaverManager manager { get; construct; }

        public signal void active_changed (bool new_value);

        public signal void wake_up_screen ();

        public GNOMEScreenSaverManager (ScreenSaverManager manager) {
            Object (manager: manager);
        }

        construct {
            manager.screen_shield.wake_up_screen.connect (() => {
                wake_up_screen ();
            });
        }

        public new void @lock () throws GLib.Error {
            manager.@lock ();
        }

        public new bool get_active () throws GLib.Error {
            return manager.get_active ();
        }

        public new void set_active (bool active) throws GLib.Error {
            manager.set_active (active);
        }

        public new uint get_active_time () throws GLib.Error {
            return manager.get_active_time ();
        }
    }
}
