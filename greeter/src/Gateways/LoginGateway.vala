/*
* Copyright (c) 2011-2017 elementary LLC (http://launchpad.net/pantheon-greeter)
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

public interface LoginGateway : GLib.Object {

    public abstract bool hide_users { get; }
    public abstract bool has_guest_account { get; }
    public abstract bool show_manual_login { get; }
    public abstract bool lock { get; }
    public abstract string default_session { get; }
    public abstract string? select_user { get; }

    /**
     * Starts the login-procedure for the passed
     */
    public abstract void login_with_mask (LoginMask mask, bool guest);

    public abstract void respond (string message);

    /**
     * Called when a user successfully logins. It gives the Greeter time
     * to run fade out animations etc.
     * The Gateway shall not accept any request from now on beside
     * the start_session call.
     */
    public signal void login_successful ();

    /**
     * Only to be called after the login_successful was fired.
     * Will start the session and exits this process.
     */
    public abstract void start_session ();

}
