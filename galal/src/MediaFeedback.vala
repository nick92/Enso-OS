//
//  Copyright (C) 2016 Rico Tzschichholz
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
    [DBus (name = "org.freedesktop.Notifications")]
    interface DBusNotifications : GLib.Object {
        public abstract uint32 notify (string app_name, uint32 replaces_id, string app_icon, string summary,
            string body, string[] actions, HashTable<string, Variant> hints, int32 expire_timeout) throws DBusError, IOError;
    }

    public class MediaFeedback : GLib.Object {
        [Compact]
        class Feedback {
            public string icon;
            public int32 level;

            public Feedback (string _icon, int32 _level) {
                icon = _icon;
                level = _level;
            }
        }

        static MediaFeedback? instance = null;
        static ThreadPool<Feedback>? pool = null;

        public static void init () {
            if (instance == null)
                instance = new MediaFeedback ();
        }

        public static void send (string icon, int val)
            requires (instance != null && pool != null) {
            try {
                pool.add (new Feedback (icon, val));
            } catch (ThreadError e) {
            }
        }

        DBusConnection? connection = null;
        DBusNotifications? notifications = null;
        uint dbus_name_owner_changed_signal_id = 0;
        uint32 notification_id = 0;

        MediaFeedback () {
            Object ();
        }

        construct {
            try {
                pool = new ThreadPool<Feedback>.with_owned_data ((ThreadPoolFunc<Feedback>) send_feedback, 1, false);
            } catch (ThreadError e) {
                critical ("%s", e.message);
                pool = null;
            }

            try {
                connection = Bus.get_sync (BusType.SESSION);
                dbus_name_owner_changed_signal_id = connection.signal_subscribe ("org.freedesktop.DBus", "org.freedesktop.DBus",
                    "NameOwnerChanged", "/org/freedesktop/DBus", null, DBusSignalFlags.NONE, (DBusSignalCallback) handle_name_owner_changed);
            } catch (IOError e) {
            }
        }

        [CCode (instance_pos = -1)]
        void handle_name_owner_changed (DBusConnection connection, string sender_name, string object_path,
            string interface_name, string signal_name, Variant parameters) {
            string name, before, after;
            parameters.get ("(sss)", out name, out before, out after);

            if (name != "org.freedesktop.Notifications")
                return;

            if (after != "" && before == "")
                new Thread<void*> (null, () => {
                    lock (notifications) {
                        try {
                            notifications = connection.get_proxy_sync<DBusNotifications> ("org.freedesktop.Notifications",
                                "/org/freedesktop/Notifications", DBusProxyFlags.NONE);
                        } catch (Error e) {
                            notifications = null;
                        }
                    }
                    return null;
                });
            else if (before != "" && after == "")
                lock (notifications) {
                    notifications = null;
                }
        }

        [CCode (instance_pos = -1)]
        void send_feedback (owned Feedback feedback) {
            var hints = new GLib.HashTable<string, Variant> (null, null);
            hints.set ("x-canonical-private-synchronous", new Variant.string ("gala-feedback"));
            hints.set ("value", new Variant.int32 (feedback.level));

            try {
                notification_id = notifications.notify ("gala-feedback", notification_id, feedback.icon, "", "", {}, hints, 2000);
            } catch (Error e) {
                critical ("%s", e.message);
            }
        }
    }
}
