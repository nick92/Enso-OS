// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
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

public class LoginBox : GtkClutter.Actor, LoginMask {
    private CredentialsArea credentials_area;
    private Avatar avatar;

    bool _selected = false;

    public bool selected {
        get {
            return _selected;
        }
        set {
            _selected = value;
            credentials_area.remove_credentials ();
            credentials_area.reveal_child = value;
        }
    }

    public string login_name {
        get {
            if (user.provides_login_name) {
                return user.name;
            }
            return credentials_area.login_name;
        }
    }

    public string login_session {
        get {
            return credentials_area.current_session;
        }
    }

    public LoginOption user { get; construct; }

    public LoginBox (LoginOption user) {
        Object (user: user);
    }

    construct {
        reactive = true;

        Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default ();

        credentials_area = new CredentialsArea (this, user);

        var path = user.avatar_path;

        if (path != null) {
            avatar = new Avatar.from_file (path, 160);
        } else {
            avatar = new Avatar.with_default_icon (160);
        }

        var grid = new Gtk.Grid ();
        grid.row_spacing = 20;
        grid.set_orientation(Gtk.Orientation.VERTICAL);
        grid.add (avatar);
        grid.add (credentials_area);
        grid.show_all ();

        var credentials_area_actor = new GtkClutter.Actor ();
        //credentials_area_actor.height = 288;
        credentials_area_actor.width = 288;

        ((Gtk.Container) credentials_area_actor.get_widget ()).add (grid);

        add_child (credentials_area_actor);

        if (user.logged_in) {
            var logged_in = new Gtk.Image.from_resource ("/io/elementary/greeter/checked.svg");

            var logged_in_actor = new GtkClutter.Actor ();
            logged_in_actor.x = 90;
            logged_in_actor.y = 140;

            ((Gtk.Container) logged_in_actor.get_widget ()).add (logged_in);

            add_child (logged_in_actor);
        }

        credentials_area.replied.connect ((answer) => {
            credentials_area.remove_credentials ();
            PantheonGreeter.login_gateway.respond (answer);
        });

        credentials_area.entered_login_name.connect ((name) => {
            start_login ();
        });

    }

    //  string get_default () {
    //      var settings = new KeyFile ();
    //      string default_wallpaper = "";
    //      //string default_wallpaper = "/usr/share/backgrounds/elementaryos-default";
    //      try {
    //          settings.load_from_file (Constants.CONF_DIR + "/pantheon-greeter.conf", KeyFileFlags.KEEP_COMMENTS);
    //          default_wallpaper = settings.get_string ("greeter", "default-icon-set");
    //      } catch (Error e) {
    //          warning (e.message);
    //      }
    //      return default_wallpaper;
    //  }

    public Avatar get_avatar() {
        return avatar;
    }

    /**
     * Starts the login procedure. Necessary to call this before the user
     * can enter something so that the LoginGateway can tell
     * us what kind of prompt he wants.
     */
    private void start_login () {
        PantheonGreeter.login_gateway.login_with_mask (this, user.is_guest);
    }

    public void pass_focus () {
        // We can't start the login when the login option isn't
        // providing a name without user interaction.
        if (user.provides_login_name) {
            start_login ();
        }
        credentials_area.pass_focus ();
    }

    void shake () {
        credentials_area.shake ();
        start_login ();
        return;
    }

    public void show_prompt (PromptType type, PromptText prompttext, string text = "") {
        credentials_area.show_prompt (type);
    }

    public void show_message (LightDM.MessageType type, MessageText messagetext, string text = "") {
        credentials_area.show_message (type, messagetext, text);
    }

    public void not_authenticated () {
        credentials_area.remove_credentials ();
        shake ();
    }

    public void login_aborted () {
        credentials_area.remove_credentials ();
    }
}
