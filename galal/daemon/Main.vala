//
//  Copyright (c) 2018 elementary LLC. (https://elementary.io)
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
    [DBus (name = "org.gnome.SessionManager")]
    public interface SessionManager : Object {
        public abstract async ObjectPath register_client (
            string app_id,
            string client_start_id
        ) throws DBusError, IOError;
    }

    [DBus (name = "org.gnome.SessionManager.ClientPrivate")]
    public interface SessionClient : Object {
        public abstract void end_session_response (bool is_ok, string reason) throws DBusError, IOError;

        public signal void stop () ;
        public signal void query_end_session (uint flags);
        public signal void end_session (uint flags);
        public signal void cancel_end_session ();
    }

    public class Daemon {
        SessionClient? sclient = null;

        public Daemon () {
            register.begin ((o, res)=> {
                bool success = register.end (res);
                if (!success) {
                    message ("Failed to register with Session manager");
                }
            });

            var menu_daemon = new MenuDaemon ();
            menu_daemon.setup_dbus ();
        }

        public void run () {
            Gtk.main ();
        }

        public static async SessionClient? register_with_session (string app_id) {
            ObjectPath? path = null;
            string? msg = null;
            string? start_id = null;

            SessionManager? session = null;
            SessionClient? session_client = null;

            start_id = Environment.get_variable ("DESKTOP_AUTOSTART_ID");
            if (start_id != null) {
                Environment.unset_variable ("DESKTOP_AUTOSTART_ID");
            } else {
                start_id = "";
                warning (
                    "DESKTOP_AUTOSTART_ID not set, session registration may be broken (not running via session?)"
                );
            }

            try {
                session = yield Bus.get_proxy (
                    BusType.SESSION,
                    "org.gnome.SessionManager",
                    "/org/gnome/SessionManager"
                );
            } catch (Error e) {
                warning ("Unable to connect to session manager: %s", e.message);
                return null;
            }

            try {
                path = yield session.register_client (app_id, start_id);
            } catch (Error e) {
                msg = e.message;
                warning ("Error registering with session manager: %s", e.message);
                return null;
            }

            try {
                session_client = yield Bus.get_proxy (BusType.SESSION, "org.gnome.SessionManager", path);
            } catch (Error e) {
                warning ("Unable to get private sessions client proxy: %s", e.message);
                return null;
            }

            return session_client;
        }

        async bool register () {
            sclient = yield register_with_session ("org.pantheon.gala.daemon");

            sclient.query_end_session.connect (() => end_session (false));
            sclient.end_session.connect (() => end_session (false));
            sclient.stop.connect (() => end_session (true));

            return true;
        }

        void end_session (bool quit) {
            if (quit) {
                Gtk.main_quit ();
                return;
            }

            try {
                sclient.end_session_response (true, "");
            } catch (Error e) {
                warning ("Unable to respond to session manager: %s", e.message);
            }
        }
    }

    public static int main (string[] args) {
        Gtk.init (ref args);

        var ctx = new OptionContext ("Gala Daemon");
        ctx.set_help_enabled (true);
        ctx.add_group (Gtk.get_option_group (false));

        try {
            ctx.parse (ref args);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            return 0;
        }

        var daemon = new Daemon ();
        daemon.run ();

        return 0;
    }
}
