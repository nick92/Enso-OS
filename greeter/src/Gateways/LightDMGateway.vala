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
 * Passes communication to LightDM.
 */
public class LightDMGateway : LoginGateway, Object {

    /**
     * The last Authenticatable that tried to login via this authenticator.
     * This variable is null in case no one has tried to login so far.
     */
    LoginMask? current_login { get; private set; default = null; }

    /**
     * True if and only if the current login got at least one prompt.
     * This is for example used for the guest login which doesn't need
     * to answer any prompt and can directly login. Here we first have to
     * ask the LoginMask for a confirmation or otherwise you would
     * automatically login as guest if you select the guest login.
     */
    bool had_prompt = false;

    /**
     * True if and only if we first await a extra-response before
     * we actually login. In case another login_with_mask call happens
     * we just set this to false again.
     */
    bool awaiting_confirmation = false;

    bool awaiting_start_session = false;

    LightDM.Greeter lightdm;

    public bool hide_users {
        get {
            return lightdm.hide_users_hint;
        }
    }
    public bool has_guest_account {
        get {
            return lightdm.has_guest_account_hint;
        }
    }
    public bool show_manual_login {
        get {
            return lightdm.show_manual_login_hint;
        }
    }
    public bool lock {
        get {
            return lightdm.lock_hint;
        }
    }
    public string default_session {
        get {
            return lightdm.default_session_hint;
        }
    }
    public string? select_user { 
        get {
            return lightdm.select_user_hint;
        }
    }

    public LightDMGateway () {
        message ("Connecting to LightDM...");
        lightdm = new LightDM.Greeter ();

        try {
            lightdm.connect_to_daemon_sync ();
        } catch (Error e) {
            warning (@"Couldn't connect to lightdm: $(e.message)");
            Posix.exit (Posix.EXIT_FAILURE);
        }
        message ("Successfully connected to LightDM.");
        lightdm.show_message.connect (show_message);
        lightdm.show_prompt.connect (show_prompt);
        lightdm.authentication_complete.connect (authentication);
    }

    public void login_with_mask (LoginMask login, bool guest) {
        if (awaiting_start_session) {
            warning ("Got login_with_mask while awaiting start_session!");
            return;
        }

        message (@"Starting authentication...");
        if (current_login != null)
            current_login.login_aborted ();

        had_prompt = false;
        awaiting_confirmation = false;

        current_login = login;
        if (guest) {
            lightdm.authenticate_as_guest ();
        } else {
            lightdm.authenticate (current_login.login_name);
        }
    }

    public void respond (string text) {
        if (awaiting_start_session) {
            warning ("Got respond while awaiting start_session!");
            return;
        }

        if (awaiting_confirmation) {
            warning ("Got user-interaction. Starting session");
            awaiting_start_session = true;
            login_successful ();
        } else {
            // We don't log this as it contains passwords etc.
            lightdm.respond (text);
        }
    }

    void show_message (string text, LightDM.MessageType type) {
        message (@"LightDM message: '$text' ($(type.to_string ()))");
        
        var messagetext = string_to_messagetext(text);
        
        if (messagetext == MessageText.FPRINT_SWIPE || messagetext == MessageText.FPRINT_PLACE) {
            // For the fprint module, there is no prompt message from PAM.
            send_prompt (PromptType.FPRINT);
        }  
        
        current_login.show_message (type, messagetext, text);
    }

    void show_prompt (string text, LightDM.PromptType type) {
        message (@"LightDM prompt: '$text' ($(type.to_string ()))");
        
        send_prompt (lightdm_prompttype_to_prompttype(type), string_to_prompttext(text), text);
    }
    
    void send_prompt (PromptType type, PromptText prompttext = PromptText.OTHER, string text = "") {
        had_prompt = true;

        current_login.show_prompt (type, prompttext, text);
    }

    PromptType lightdm_prompttype_to_prompttype(LightDM.PromptType type) {
        if (type == LightDM.PromptType.SECRET) {
            return PromptType.SECRET;
        }
        
        return PromptType.QUESTION;
    }
    
    PromptText string_to_prompttext (string text) {
        if (text == "Password: ") {
            return PromptText.PASSWORD;
        }
        
        if (text == "login: ") {
            return PromptText.USERNAME;
        }
        
        return PromptText.OTHER;
    }
    
    MessageText string_to_messagetext (string text) {
        // Ideally this would query PAM and ask which module is currently active,
        // but since we're running through LightDM we don't have that ability.
        // There should at be a state machine to transition to and from the 
        // active module depending on the messages recieved. But, this is can go
        // wrong quickly. 
        // The reason why this is needed is, for example, we can get the "An
        // unknown error occured" message from pam_fprintd, but we can get it 
        // from some other random module as well. You never know.
        // Maybe it's worth adding some LightDM/PAM functionality for this? 
        // The PAM "feature" which makes it all tricky is that modules can send 
        // arbitrary messages to the stream and it's hard to analyze or keep track
        // of them programmatically. 
        // Also, there doesn't seem to be a way to give the user a choice over
        // which module he wants to use to authenticate (ie. maybe today I have
        // a bandaid over my finger and I can't scan it so I have to wait for it
        // time out, if I didn't disable that in the settings)
        
        // These messages are taken from here: 
        //  - https://cgit.freedesktop.org/libfprint/fprintd/tree/pam/fingerprint-strings.h
        //  - https://cgit.freedesktop.org/libfprint/fprintd/tree/pam/pam_fprintd.c
        
        if (text == GLib.dgettext("fprintd","An unknown error occured")) {
            // LIGHTDM_MESSAGE_TYPE_ERROR
            return MessageText.FPRINT_ERROR;
        } else if (check_fprintd_string(text, "Swipe", "across")) {
            // LIGHTDM_MESSAGE_TYPE_INFO
            return MessageText.FPRINT_SWIPE;
        } else if (text == GLib.dgettext("fprintd", "Swipe your finger again")) {
            // LIGHTDM_MESSAGE_TYPE_ERROR
            return MessageText.FPRINT_SWIPE_AGAIN;
        } else if (text == GLib.dgettext("fprintd", "Swipe was too short, try again")) {
            // LIGHTDM_MESSAGE_TYPE_ERROR
            return MessageText.FPRINT_SWIPE_TOO_SHORT;
        } else if (text == GLib.dgettext("fprintd", "Your finger was not centered, try swiping your finger again")) {
            // LIGHTDM_MESSAGE_TYPE_ERROR
            return MessageText.FPRINT_NOT_CENTERED;
        } else if (text == GLib.dgettext("fprintd", "Remove your finger, and try swiping your finger again")) {
            // LIGHTDM_MESSAGE_TYPE_ERROR
            return MessageText.FPRINT_REMOVE;
        } else if (check_fprintd_string(text, "Place", "on")) {
            // LIGHTDM_MESSAGE_TYPE_INFO
            return MessageText.FPRINT_PLACE;
        } else if (text == GLib.dgettext("fprintd", "Place your finger on the reader again")) {
            // LIGHTDM_MESSAGE_TYPE_ERROR
            return MessageText.FPRINT_PLACE_AGAIN;
        } else if (text == GLib.dgettext("fprintd", "Failed to match fingerprint")) {
            // LIGHTDM_MESSAGE_TYPE_ERROR
            return MessageText.FPRINT_NO_MATCH;
        } else if (text == GLib.dgettext("fprintd", "Verification timed out")) {
            // LIGHTDM_MESSAGE_TYPE_INFO
            return MessageText.FPRINT_TIMEOUT;
        } else if (text == "Login failed") {
            return MessageText.FAILED;
        } 

        return MessageText.OTHER;
    }
    
    public bool check_fprintd_string(string text, string action, string position) {
        string[] fingers = {"finger",
                        "left thumb", "left index finger", "left middle finger", "left ring finger", "left little finger",
                        "right thumb", "right index finger", "right middle finger", "right ring finger", "right little finger"};
                        
        foreach (var finger in fingers) {
            var english_string = action.concat(" your ", finger, " ", position, " %s");
            
            // load translations from the fprintd domain
            if (text.has_prefix (GLib.dgettext ("fprintd", english_string).printf (""))) {
                return true;
            }

        }
        
        return false;
    }

    public void start_session () {
        if (!awaiting_start_session) {
            warning ("Got start_session without awaiting it.");
        }
        message (@"Starting session $(current_login.login_session)");
        PantheonGreeter.instance.set_greeter_state ("last-user",
                                            current_login.login_name);
        try {
            lightdm.start_session_sync (current_login.login_session);
        } catch (Error e) {
            error (e.message);
        }
    }

    void authentication () {
        if (lightdm.is_authenticated) {
            // Check if the LoginMask actually got userinput that confirms
            // that the user wants to start a session now.
            if (had_prompt) {
                // If yes, start a session
                awaiting_start_session = true;
                login_successful ();
            } else {
                message ("Auth complete, but we await user-interaction before we"
                        + "start a session");
                // If no, send a prompt and await the confirmation via respond.
                // This variables is checked in respond as a special case.
                awaiting_confirmation = true;
                current_login.show_prompt (PromptType.CONFIRM_LOGIN);
            }
        } else {
            current_login.not_authenticated ();
        }
    }
}
