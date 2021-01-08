/*
* Copyright (c) 2016-2017 elementary LLC. (http://launchpad.net/pantheon-greeter)
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

public class UserLogin : LoginOption {

    public LightDM.User lightdm_user { get; private set; }
    private string background_path;

    public UserLogin (int index, LightDM.User user) {
        base (index);
        this.lightdm_user = user;
        
        warning(lightdm_user.background);

        // Copied straight from Widgets/Wallpaper.vala
        // Fix if problematic
        // Allows user to configure greeter to never use user wallpapers
        bool default_wallpaper=false;
        var settings = new KeyFile();
        try {
            settings.load_from_file (Path.build_filename (Constants.CONF_DIR, "pantheon-greeter.conf"), KeyFileFlags.KEEP_COMMENTS);
            default_wallpaper = settings.get_boolean ("greeter", "use-default-wallpaper");
        } catch (Error e) {
            warning (e.message);
        }
        if (!default_wallpaper) {
            try {
                string path = Path.build_filename ("/var", "lib", "lightdm-data", lightdm_user.name, "wallpaper");
                var background_directory = File.new_for_path (path);
                var enumerator = background_directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);
                
                FileInfo file_info;
                string file_name = "";
                while ((file_info = enumerator.next_file ()) != null) {
                    if (file_info.get_file_type () == FileType.REGULAR) {
                        file_name = file_info.get_name ();
                        break;
                    }
                }

                path = Path.build_filename (path, file_name);
                background_path = path;
            } catch (Error e) {
                warning (e.message);
                background_path = lightdm_user.background;
            }
        } else {
            background_path = "";
        }
    }

    public override string? avatar_path {
        get {
            return lightdm_user.image;
        }
    }

    public override string background {
        get {
            //return lightdm_user.background;
            return background_path;
        }
    }

    public override string display_name {
        get {
            return lightdm_user.display_name;
        }
    }

    public override string name {
        get {
            return lightdm_user.name;
        }
    }

    public override bool logged_in {
        get {
            return lightdm_user.logged_in;
        }
    }

    public override string session {
        get {
            return lightdm_user.session;
        }
    }
}
