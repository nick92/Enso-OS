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

public enum PromptType {
    /**
     * Reply with the password.
     */
    SECRET,
    /**
     * Reply with the password.
     */
    QUESTION,
    /**
     * Reply with any text to confirm that you want to login.
     */
    CONFIRM_LOGIN,
    /**
     * Show fingerprint prompt
     */
    FPRINT
}

public enum PromptText {
    /**
     * A message asking for username entry
     */
    USERNAME,
    /**
     * A message asking for password entry
     */
    PASSWORD,
    /**
     * The message was not in the expected list
     */
    OTHER
}

/**
 * A LoginMask is for example a UI such as the LoginBox that communicates with
 * the user.
 * It forms with the LoginGateway a protocol for logging in users. The steps
 * are roughly:
 * 1. gateway.login_with_mask - Call this as soon as you know the username
 *           The gateway will get the login_name via the property of your
 *           mask.
 * 2. mask.show_prompt or mask.show_message - one of both is called and the
 *           mask has to display that to the user.
 *           show_prompt also demands that you answer
 *           via gateway.respond.
 * 3. Repeat Step 2 until the gateway fires login_successful
 * 4. Call gateway.start_session after login_successful is called
 *
 *
 */
public interface LoginMask : GLib.Object {

    public abstract string login_name { get; }
    public abstract string login_session { get; }

    /**
     * Present a prompt to the user. The interface can answer via the
     * respond method of the LoginGateway.
     */
     public abstract void show_prompt (PromptType type, PromptText prompttext = PromptText.OTHER, string text = "");
     
     public abstract void show_message (LightDM.MessageType type, MessageText messagetext = MessageText.OTHER, string text = "");

     public abstract void not_authenticated ();

    /**
     * The login-try was aborted because another LoginMask wants to login.
     */
    public abstract void login_aborted ();
}
