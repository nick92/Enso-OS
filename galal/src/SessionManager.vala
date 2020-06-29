//
//  Copyright (C) 2018 Adam Bieńkowski
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

// Reference code by the Solus Project:
// https://github.com/solus-project/budgie-desktop/blob/master/src/wm/shim.vala

namespace Gala {
    [DBus (name = "io.elementary.wingpanel.session.EndSessionDialog")]
    public interface WingpanelEndSessionDialog : Object {
        public signal void confirmed_logout ();
        public signal void confirmed_reboot ();
        public signal void confirmed_shutdown ();
        public signal void canceled ();
        public signal void closed ();

        public abstract void open (uint type, uint timestamp, uint open_length, ObjectPath[] inhibiters) throws DBusError, IOError;
    }

    [DBus (name = "org.gnome.SessionManager.EndSessionDialog")]
    public class SessionManager : Object {
        static SessionManager? instance;

        [DBus (visible = false)]
        public static unowned SessionManager init () {
            if (instance == null) {
                instance = new SessionManager ();
            }

            return instance;
        }

        public signal void confirmed_logout ();
        public signal void confirmed_reboot ();
        public signal void confirmed_shutdown ();
        public signal void canceled ();
        public signal void closed ();

        WingpanelEndSessionDialog? proxy = null;

        SessionManager () {
            Bus.watch_name (BusType.SESSION, "io.elementary.wingpanel.session.EndSessionDialog",
                BusNameWatcherFlags.NONE, proxy_appeared, proxy_vanished);
        }

        void get_proxy_cb (Object? o, AsyncResult? res) {
            try {
                proxy = Bus.get_proxy.end (res);
            } catch (Error e) {
                warning ("Could not connect to io.elementary.wingpanel.session.EndSessionDialog proxy: %s", e.message);
                return;
            }

            proxy.confirmed_logout.connect (() => confirmed_logout ());
            proxy.confirmed_reboot.connect (() => confirmed_reboot ());
            proxy.confirmed_shutdown.connect (() => confirmed_shutdown ());
            proxy.canceled.connect (() => canceled ());
            proxy.closed.connect (() => closed ());
        }

        void proxy_appeared () {
            Bus.get_proxy.begin<WingpanelEndSessionDialog> (BusType.SESSION,
                "io.elementary.wingpanel.session.EndSessionDialog", "/io/elementary/wingpanel/session/EndSessionDialog",
                0, null, get_proxy_cb);
        }

        void proxy_vanished () {
            proxy = null;
        }

        public void open (uint type, uint timestamp, uint open_length, ObjectPath[] inhibiters) throws DBusError, IOError {
            if (proxy == null) {
                throw new DBusError.FAILED ("io.elementary.wingpanel.session.EndSessionDialog DBus interface is not registered.");
            }

            proxy.open (type, timestamp, open_length, inhibiters);
        }
    }
}
