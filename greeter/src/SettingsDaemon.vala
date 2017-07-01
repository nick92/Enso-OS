/* -*- Mode:Vala; indent-tabs-mode:nil; tab-width:4 -*-
 *
 * Copyright (C) 2011 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Michael Terry <michael.terry@canonical.com>
 */

public class SettingsDaemon : Object {
    private SessionManagerInterface session_manager;
    private int n_names = 0;

    public void start () {
        string[] disabled = { "org.gnome.settings-daemon.plugins.clipboard",
                              "org.gnome.settings-daemon.plugins.gconf",
                              "org.gnome.settings-daemon.plugins.gsdwacom",
                              "org.gnome.settings-daemon.plugins.housekeeping",
                              "org.gnome.settings-daemon.plugins.keybindings",
                              "org.gnome.settings-daemon.plugins.keyboard",
                              "org.gnome.settings-daemon.plugins.media-keys",
                              "org.gnome.settings-daemon.plugins.mouse",
                              "org.gnome.settings-daemon.plugins.print-notifications",
                              "org.gnome.settings-daemon.plugins.smartcard",
                              "org.gnome.settings-daemon.plugins.sound",
                              "org.gnome.settings-daemon.plugins.wacom" };

        string[] enabled =  { "org.gnome.settings-daemon.plugins.a11y-keyboard",
                              "org.gnome.settings-daemon.plugins.font",
                              "org.gnome.settings-daemon.plugins.background",
                              "org.gnome.settings-daemon.plugins.a11y-settings",
                              "org.gnome.settings-daemon.plugins.color",
                              "org.gnome.settings-daemon.plugins.cursor",
                              "org.gnome.settings-daemon.plugins.power",
                              "org.gnome.settings-daemon.plugins.xrandr",
                              "org.gnome.settings-daemon.plugins.xsettings" };

        foreach (var schema in disabled) {
            set_plugin_enabled (schema, false);
        }

        foreach (var schema in enabled) {
            set_plugin_enabled (schema, true);
        }

        /* Pretend to be GNOME session */
        session_manager = new SessionManagerInterface ();
        n_names++;
        GLib.Bus.own_name (BusType.SESSION, "org.gnome.SessionManager", BusNameOwnerFlags.NONE,
                           (c) => {
                               try {
                                   c.register_object ("/org/gnome/SessionManager", session_manager);
                               } catch (Error e) {
                                   warning ("Failed to register /org/gnome/SessionManager: %s", e.message);
                               }
                           },
                           () => {
                               debug ("Acquired org.gnome.SessionManager");
                               start_settings_daemon ();
                           },
                           () => debug ("Failed to acquire name org.gnome.SessionManager"));
    }

    private void set_plugin_enabled (string schema_name, bool enabled) {
        var source = SettingsSchemaSource.get_default ();
        var schema = source.lookup (schema_name, false);
        if (schema != null) {
            var settings = new Settings (schema_name);
            settings.set_boolean ("active", enabled);
        }
    }

    private void start_settings_daemon () {
        n_names--;
        if (n_names != 0) {
            return;
        }

        debug ("All bus names acquired, starting gnome-settings-daemon");

        try {
            Process.spawn_command_line_async ("gnome-settings-daemon");
        } catch (SpawnError e) {
            debug ("Could not start gnome-settings-daemon: %s", e.message);
        }
    }
}

[DBus (name="org.gnome.SessionManager")]
public class SessionManagerInterface : Object
{
    public bool session_is_active { get { return true; } }
    public string session_name { get { return "pantheon"; } }
    public uint32 inhibited_actions { get { return 0; } }
}
