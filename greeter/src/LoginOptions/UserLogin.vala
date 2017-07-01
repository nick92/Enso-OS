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

    public UserLogin (int index, LightDM.User user) {
        base (index);
        this.lightdm_user = user;
    }

    public override string? avatar_path {
        get {
            return lightdm_user.image;
        }
    }

    public override string background {
        get {
            return lightdm_user.background;
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
