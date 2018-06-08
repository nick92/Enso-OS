/*
 * Copyright (c) 2011-2015 Wingpanel Developers (http://launchpad.net/wingpanel)
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

[DBus (name = "org.freedesktop.login1.Manager")]
interface Manager : Object {
    public signal void prepare_for_sleep (bool sleeping);
}

public class DateTime.Services.TimeManager : Gtk.Calendar {
    private static TimeManager? instance = null;

    public signal void minute_changed ();

    private GLib.DateTime? current_time = null;
    private uint timeout_id = 0;
    private Manager? manager = null;

    public TimeManager () {
        update_current_time ();

        if (current_time == null) {
            return;
        }

        add_timeout ();
        try {
            // Listen for the D-BUS server that controls time settings
            Bus.watch_name (BusType.SYSTEM, "org.freedesktop.timedate1", BusNameWatcherFlags.NONE, on_watch, on_unwatch);
            // Listen for the signal that is fired when waking up from sleep, then update time
            manager = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
            manager.prepare_for_sleep.connect ((sleeping) => {
                if (!sleeping) {
                    update_current_time ();
                    minute_changed ();
                    add_timeout ();
                }
            });
        } catch (Error e) {
            warning (e.message);
        }
    }

    private void on_watch (DBusConnection conn) {
        // Start updating the time display quicker because someone is changing settings
        add_timeout (true);
    }

    private void on_unwatch (DBusConnection conn) {
        // Stop updating the time display quicker
        add_timeout (false);
    }

    private void add_timeout (bool update_fast = false) {
        var interval = update_fast ? 500 : calculate_time_until_next_minute ();

        if (timeout_id > 0) {
            Source.remove (timeout_id);
        }

        timeout_id = Timeout.add (interval, () => {
            update_current_time ();
            minute_changed ();
            add_timeout (update_fast);

            return false;
        });
    }

    public string format (string format) {
        if (current_time == null) {
            return "undef";
        }

        return current_time.format (format);
    }

    public GLib.DateTime get_current_time () {
        return current_time;
    }

    private void update_current_time () {
        var local_time = new GLib.DateTime.now_local ();

        if (local_time == null) {
            critical ("Can't get the local time.");

            return;
        }

        current_time = local_time;
    }

    private uint calculate_time_until_next_minute () {
        if (current_time == null) {
            return 60 * 1000;
        }

        var seconds_until_next_minute = 60 - (current_time.to_unix () % 60);

        return (uint)seconds_until_next_minute * 1000;
    }

    public static TimeManager get_default () {
        if (instance == null) {
            instance = new TimeManager ();
        }

        return instance;
    }
}
