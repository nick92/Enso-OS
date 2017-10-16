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

public enum MessageText {
    FPRINT_SWIPE,
    FPRINT_SWIPE_AGAIN,
    FPRINT_SWIPE_TOO_SHORT,
    FPRINT_NOT_CENTERED,
    FPRINT_REMOVE,
    FPRINT_PLACE,
    FPRINT_PLACE_AGAIN,
    FPRINT_NO_MATCH,
    FPRINT_TIMEOUT,
    FPRINT_ERROR,
    FAILED,
    OTHER
}

public class FingerprintCredentials : Gtk.Grid, Credentials {
    Gtk.Label label;

    public FingerprintCredentials () {
        //var image = new Gtk.Image.from_file (Constants.PKGDATADIR + "/fingerprint.svg");
        //image.margin = 6;

        /*var box = new Gtk.Grid ();
        box.get_style_context ().add_class ("fingerprint");
        //box.add (image);*/

        label = new Gtk.Label ("");
        label.valign = Gtk.Align.CENTER;
        
        var label_style_context = label.get_style_context ();
        label_style_context.add_class ("h3");
        label_style_context.add_class ("fingerprint-label");

        //attach (box, 0, 0, 1, 1);   
        attach (label, 1, 0, 1, 1);
        column_spacing = 6;
    }

    public void show_message (LightDM.MessageType type, MessageText messagetext = MessageText.OTHER, string text = "") {
        var label_style_context = label.get_style_context ();
        
        if (type == LightDM.MessageType.INFO) {
            label_style_context.remove_class (Gtk.STYLE_CLASS_ERROR);
            label_style_context.add_class (Gtk.STYLE_CLASS_INFO);
        } else {
            label_style_context.remove_class (Gtk.STYLE_CLASS_INFO);
            label_style_context.add_class (Gtk.STYLE_CLASS_ERROR);
        }

        switch (messagetext) {
            case MessageText.FPRINT_SWIPE:
                label.label = _("Swipe your finger");
                break;
            case MessageText.FPRINT_PLACE:
                label.label = _("Place your finger");
                break;
            case MessageText.FPRINT_REMOVE:
                label.label = _("Remove your finger and try again.");
                break;
            case MessageText.FPRINT_NOT_CENTERED:
                label.label = _("Center your finger and try again.");
                break;
            default:
                label.label = text;
                break;
        }
    }
}
