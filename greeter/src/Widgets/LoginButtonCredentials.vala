/*
* Copyright (c) 2011-2017 elementary LLC. (http://launchpad.net/pantheon-greeter)
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
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
*/

public class LoginButtonCredentials : Gtk.Button, Credentials {
    construct {
        label = _("Log In");
        get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        clicked.connect (() => {
            // It doesn't matter what we answer, the confirmation
            // is that we reply at all.
            replied ("");
        });
    }
    
    public void show_message (LightDM.MessageType type, MessageText messagetext = MessageText.OTHER, string text = "") {
        // there are no messages to display
    }
}
