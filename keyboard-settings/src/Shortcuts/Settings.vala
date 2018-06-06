/*
* Copyright (c) 2017 elementary, LLC. (https://elementary.io)
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
* Boston, MA 02110-1301 USA
*/

namespace Pantheon.Keyboard.Shortcuts
{
    private enum Schema { WM, MUTTER, GALA, MEDIA, COUNT, XFCE }

    // helper class for gsettings
    // note that media key are stored as strings, all others as string vectors
    class Settings : GLib.Object
    {
        private GLib.Settings[] schemas;
        private string[] schema_names;

        public Settings ()
        {
            schema_names = {
                "org.gnome.desktop.wm.keybindings",
                "org.gnome.mutter.keybindings",
                "org.pantheon.desktop.gala.keybindings",
                "org.gnome.settings-daemon.plugins.media-keys"
            };

            foreach (var name in schema_names)
            {
                var schema_source = GLib.SettingsSchemaSource.get_default ();

                // check if schema exists
                var schema = schema_source.lookup (name, true);

                if (schema == null) {
                    warning ("Schema \"%s\" is not installed on your system.", name);
                    schemas += (GLib.Settings) null;
                } else {
                    schemas += new GLib.Settings.full (schema, null, null);
                }
            }
        }

        private bool valid (Schema schema, string key)
        {
            // check if schema exists
            if (schema < 0 || schema >= Schema.COUNT)
                return false;

            if (schemas[schema] == null)
                return false;

             // check if key exists
            foreach (string tmp_key in schemas[schema].list_keys ())
                if (key == tmp_key)
                    return true;

            warning ("Key \"%s\" does not exist in schema \"%s\".", key, schema_names[schema]);
            return false;
        }

        // get/set methods for shortcuts in gsettings
        // require and return class Shortcut objects
        public Shortcut get_val (Schema schema, string key)
        {
            if (!valid (schema, key))
                return (Shortcut) null;

            if (schema == Schema.MEDIA)
                return new Shortcut.parse (schemas[schema].get_string (key));
            else
                return new Shortcut.parse ((schemas[schema].get_strv (key)) [0]);
        }

        public bool set_val  (Schema schema, string key, Shortcut sc)
        {
            if (!valid (schema, key))
                return false;

            if (schema == Schema.MEDIA)
                schemas[schema].set_string (key, sc.to_gsettings ());
            else
                schemas[schema].set_strv (key, {sc.to_gsettings ()});
            return true;
        }

        public void reset (Schema schema, string key)
        {
            if (!valid (schema, key))
                return;

            if (! schemas[schema].is_writable (key))
                return;
            schemas[schema].reset (key);
        }
    }
}
