// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2013 elementary Developers

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/>

    END LICENSE
***/

[DBus (name = "org.freedesktop.Accounts.User")]
interface AccountsServiceUser : Object {
    public abstract bool locked { get; }
}

public class UserList : Object {

    public int size { get; private set; }

    Gee.ArrayList<LoginOption> users = new Gee.ArrayList<LoginOption> ();

    LoginOption _current_user;

    public LoginOption current_user {
        get {
            return _current_user;
        }
        set {
            if (value != current_user) {
                _current_user = value;
                current_user_changed (value);
            }
        }
    }

    public signal void current_user_changed (LoginOption user);

    public UserList (LightDM.UserList ld_users) {
        int index = 0;
        if (!PantheonGreeter.login_gateway.hide_users) {
            foreach (LightDM.User this_user in ld_users.users) {
                try {
                    string uid = "%d".printf ((int) this_user.get_uid ());
                    AccountsServiceUser accounts_user = Bus.get_proxy_sync (BusType.SYSTEM,
                        "org.freedesktop.Accounts",
                        "/org/freedesktop/Accounts/User" + uid);
                    if (accounts_user.locked == true) {
                        continue;
                    }
                } catch (Error e) {
                    warning (e.message);
                }
                users.add (new UserLogin (index, this_user));
                index++;
            }
        }

        if (PantheonGreeter.login_gateway.has_guest_account) {
            users.add (new GuestLogin (index));
            index++;
        }
        if (PantheonGreeter.login_gateway.show_manual_login) {
            users.add (new ManualLogin (index));
            index++;
        }
        size = index;
    }

    public LoginOption get_user (int i) {
        return users.get (i);
    }

    public void select_next_user () {
        current_user = get_next (current_user);
    }

    public void select_prev_user () {
        current_user = get_prev (current_user);
    }

    public LoginOption get_next (LoginOption user) {
        int i = user.index;
        if(i < size - 1 && size > 0)
            return get_user (i + 1);
        return get_user (size - 1);
    }

    public LoginOption get_prev (LoginOption user) {
        int i = user.index;
        if(i > 0)
            return get_user (i - 1);
        return get_user (0);
    }
}
