/*
* Copyright (c) 2014-2017 elementary LLC. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
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

namespace SwitchboardPlugUserAccounts {
    public class InfobarNotifier : Object {
        private bool        error = false;
        private string      error_message = "";
        private bool        reboot = false;

        public signal void  error_notified ();
        public signal void  reboot_notified ();

        public InfobarNotifier () { }

        public void set_error (string error_message) {
            error = true;
            this.error_message = error_message;
            error_notified ();
        }

        public void unset_error () {
            error = false;
            error_message = "";
            error_notified ();
        }

        public bool is_error () {
            return error;
        }

        public void set_reboot () {
            reboot = true;
            reboot_notified ();
        }

        public bool is_reboot () {
            return reboot;
        }

        public string get_error_message () {
            return error_message;
        }

        private static GLib.Once<InfobarNotifier> instance;

        public static unowned InfobarNotifier get_default () {
            return instance.once (() => { return new InfobarNotifier (); });
        }
    }
}
