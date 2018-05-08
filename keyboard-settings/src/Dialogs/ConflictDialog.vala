/*
* Copyright (c) 2017-2018 elementary, LLC. (https://elementary.io)
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

public class ConflictDialog : Granite.MessageDialog {
    public signal void reassign ();

    public ConflictDialog (string shortcut, string conflict_action, string this_action) {
        Object (
            image_icon: new GLib.ThemedIcon ("dialog-warning"),
            primary_text: _("%s is already used for %s").printf (shortcut, conflict_action),
            secondary_text: _("If you reassign the shortcut to %s, %s will be disabled.").printf (this_action, conflict_action)
        );
    }

    construct {
        deletable = false;
        modal = true;
        resizable = false;

        add_button (_("Cancel"), 0);

        var reassign_button = add_button (_("Reassign"), 1);
        reassign_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        response.connect ((response_id) => {
            if (response_id == 1) {
                reassign ();
            }

            destroy();
        });
    }
}
