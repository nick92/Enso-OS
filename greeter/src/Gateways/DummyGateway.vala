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

/**
 * For testing purposes a Gateway which only allows the guest to login.
 */
public class DummyGateway : LoginGateway, Object {

    public bool hide_users { get { return false; } }
    public bool has_guest_account { get { return true; } }
    public bool show_manual_login { get { return true; } }
    public bool lock { get {return false; } }
    public string default_session { get { return ""; } }
    public string? select_user { get { return null; } }

    LoginMask last_login_mask;

    bool last_was_guest = true;

    public void login_with_mask (LoginMask mask, bool guest) {
        if (last_login_mask != null)
            mask.login_aborted ();

        last_was_guest = guest;
        last_login_mask = mask;
        Idle.add (() => {
            mask.show_prompt (guest ? PromptType.CONFIRM_LOGIN : PromptType.SECRET, guest ? PromptText.OTHER : PromptText.PASSWORD);
            return false;
        });
    }

    public void respond (string message) {
        if (last_was_guest) {
            Idle.add (() => {
                login_successful ();
                return false;
            });
        } else {
            Idle.add (() => {
                last_login_mask.not_authenticated ();
                return false;
            });
        }
    }

    public void start_session () {
        message ("Started session");
        Posix.exit (Posix.EXIT_SUCCESS);
    }

}
