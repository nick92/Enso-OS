//
//  Copyright 2020 elementary, Inc. (https://elementary.io)
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Gala {
    [DBus (name = "org.freedesktop.login1.Manager")]
    interface LoginManager : Object {
        public signal void prepare_for_sleep (bool about_to_suspend);

        public abstract GLib.ObjectPath get_session (string session_id) throws GLib.Error;

        public abstract UnixInputStream inhibit (string what, string who, string why, string mode) throws GLib.Error;
    }

    [DBus (name = "org.freedesktop.login1.Session")]
    interface LoginSessionManager : Object {
        public abstract bool active { get; }

        public signal void lock ();
        public signal void unlock ();

        public abstract void set_locked_hint (bool locked) throws GLib.Error;
    }

    public struct LoginDisplay {
        string session;
        GLib.ObjectPath objectpath;
    }

    [DBus (name = "org.freedesktop.login1.User")]
    interface LoginUserManager : Object {
        public abstract LoginDisplay? display { owned get; }
    }

    [CCode (type_signature = "u")]
    enum PresenceStatus {
        AVAILABLE = 0,
        INVISIBLE = 1,
        BUSY = 2,
        IDLE = 3
    }

    [DBus (name = "org.gnome.SessionManager.Presence")]
    interface SessionPresence : Object {
        public abstract PresenceStatus status { get; }
        public signal void status_changed (PresenceStatus new_status);
    }

    [DBus (name = "org.freedesktop.DisplayManager.Seat")]
    interface DisplayManagerSeat : Object {
        public abstract void switch_to_greeter () throws GLib.Error;
    }

    public class ScreenShield : Clutter.Actor {
        // Animation length for when computer has been sitting idle and display
        // is about to turn off
        public const uint LONG_ANIMATION_TIME = 3000;
        // Animation length used for manual lock action (i.e. Super+L or GUI action)
        public const uint SHORT_ANIMATION_TIME = 300;

        private const string LOCK_ENABLED_KEY = "lock-enabled";
        private const string LOCK_PROHIBITED_KEY = "disable-lock-screen";
        private const string LOCK_ON_SUSPEND_KEY = "lock-on-suspend";

        public signal void active_changed ();
        public signal void wake_up_screen ();

        // Screensaver active but not necessarily locked
        public bool active { get; private set; default = false; }

        public bool is_locked { get; private set; default = false; }
        public bool in_greeter { get; private set; default = false; }
        public int64 activation_time  { get; private set; default = 0; }

        public WindowManager wm { get; construct; }

        private ModalProxy? modal_proxy;

        private LoginManager? login_manager;
        private LoginUserManager? login_user_manager;
        private LoginSessionManager? login_session;
        private SessionPresence? session_presence;

        private DisplayManagerSeat? display_manager;

        private uint animate_id = 0;

        private UnixInputStream? inhibitor;

        private GLib.Settings screensaver_settings;
        private GLib.Settings lockdown_settings;
        private GLib.Settings gala_settings;

        private bool connected_to_buses = false;

        public ScreenShield (WindowManager wm) {
            Object (wm: wm);
        }

        construct {
            // We use the lock-enabled key in the GNOME namespace instead of our own
            // because it's also used by gsd-power
            screensaver_settings = new GLib.Settings ("org.gnome.desktop.screensaver");

            // Vanilla GNOME doesn't have a key that separately enables/disables locking on
            // suspend, so we have a key in our own namespace for this
            gala_settings = new GLib.Settings ("io.elementary.desktop.screensaver");
            lockdown_settings = new GLib.Settings ("org.gnome.desktop.lockdown");

            visible = false;
            reactive = true;

            // Listen for keypresses or mouse movement
            key_press_event.connect ((event) => {
                on_user_became_active ();
            });

            motion_event.connect ((event) => {
                on_user_became_active ();
            });

            background_color = Clutter.Color.from_string ("black");

            expand_to_screen_size ();

            bool success = true;

            try {
                login_manager = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
                login_user_manager = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1/user/self");

                // Listen for sleep/resume events from logind
                login_manager.prepare_for_sleep.connect (prepare_for_sleep);
                login_session = get_current_session_manager ();
                if (login_session != null) {
                    // Listen for lock unlock events from logind
                    login_session.lock.connect (() => @lock (false));
                    login_session.unlock.connect (() => {
                        deactivate (false);
                        in_greeter = false;
                    });

                    login_session.notify.connect (sync_inhibitor);
                    sync_inhibitor ();
                }
            } catch (Error e) {
                success = false;
                critical ("Unable to connect to logind bus, screen locking disabled: %s", e.message);
            }

            try {
                session_presence = Bus.get_proxy_sync (BusType.SESSION, "org.gnome.SessionManager", "/org/gnome/SessionManager/Presence");
                on_status_changed (session_presence.status);
                session_presence.status_changed.connect ((status) => on_status_changed (status));
            } catch (Error e) {
                success = false;
                critical ("Unable to connect to session presence bus, screen locking disabled: %s", e.message);
            }


            string? seat_path = GLib.Environment.get_variable ("XDG_SEAT_PATH");
            if (seat_path != null) {
                try {
                    display_manager = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.DisplayManager", seat_path);
                } catch (Error e) {
                    success = false;
                    critical ("Unable to connect to display manager bus, screen locking disabled");
                }
            } else {
                success = false;
                critical ("XDG_SEAT_PATH unset, screen locking disabled");
            }

            connected_to_buses = success;
        }

        public void expand_to_screen_size () {
            int screen_width, screen_height;
#if HAS_MUTTER330
            wm.get_display ().get_size (out screen_width, out screen_height);
#else
            wm.get_screen ().get_size (out screen_width, out screen_height);
#endif
            width = screen_width;
            height = screen_height;
        }

        private void prepare_for_sleep (bool about_to_suspend) {
            if (!connected_to_buses) {
                return;
            }

            if (about_to_suspend) {
                if (gala_settings.get_boolean (LOCK_ON_SUSPEND_KEY)) {
                    debug ("about to sleep, locking screen");
                    this.@lock (false);
                }
            } else {
                debug ("resumed from suspend, waking screen");
                on_user_became_active ();
                wake_up_screen ();
                expand_to_screen_size ();
            }
        }

        // status becomes idle after interval defined at /org/gnome/desktop/session/idle-delay
        private void on_status_changed (PresenceStatus status) {
            if (status != PresenceStatus.IDLE || !connected_to_buses) {
                return;
            }

            debug ("session became idle, activating screensaver");

            activate (true);
        }

        // We briefly inhibit sleep so that we can try and lock before sleep occurs if necessary
        private void sync_inhibitor () {
            if (!connected_to_buses) {
                return;
            }

            var lock_enabled = gala_settings.get_boolean (LOCK_ON_SUSPEND_KEY);
            var lock_prohibited = lockdown_settings.get_boolean (LOCK_PROHIBITED_KEY);

            var inhibit = login_session != null && login_session.active && !active && lock_enabled && !lock_prohibited;
            if (inhibit) {
                try {
                    var new_inhibitor = login_manager.inhibit ("sleep", "Pantheon", "Pantheon needs to lock the screen", "delay");
                    if (inhibitor != null) {
                        inhibitor.close ();
                        inhibitor = null;
                    }

                    inhibitor = new_inhibitor;
                } catch (Error e) {
                    warning ("Unable to inhibit sleep, may be unable to lock before sleep starts: %s", e.message);
                }
            } else {
                if (inhibitor != null) {
                    try {
                        inhibitor.close ();
                    } catch (Error e) {
                        warning ("Unable to remove sleep inhibitor: %s", e.message);
                    }

                    inhibitor = null;
                }
            }
        }

        private void on_user_became_active () {
            if (!connected_to_buses) {
                return;
            }

            // User became active in some way, switch to the greeter if we're not there already
            if (is_locked && !in_greeter) {
                debug ("user became active, switching to greeter");
                cancel_animation ();
                try {
                    display_manager.switch_to_greeter ();
                } catch (Error e) {
                    critical ("Unable to switch to greeter to unlock: %s", e.message);
                }
                in_greeter = true;
            // Otherwise, we're in screensaver mode, just deactivate
            } else if (!is_locked) {
                debug ("user became active in unlocked session, closing screensaver");
                deactivate (false);
            }
        }

        private LoginSessionManager? get_current_session_manager () throws GLib.Error {
            string? session_id = GLib.Environment.get_variable ("XDG_SESSION_ID");
            if (session_id == null) {
                debug ("Unset XDG_SESSION_ID, asking logind");
                if (login_user_manager == null) {
                    return null;
                }

                session_id = login_user_manager.display.session;
            }

            if (session_id == null) {
                return null;
            }

            var session_path = login_manager.get_session (session_id);
            LoginSessionManager? session = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", session_path);

            return session;
        }

        public void @lock (bool animate) {
            if (is_locked || !connected_to_buses) {
                return;
            }

            if (lockdown_settings.get_boolean (LOCK_PROHIBITED_KEY)) {
                debug ("Lock prohibited, ignoring lock request");
                return;
            }

            is_locked = true;

            activate (animate, SHORT_ANIMATION_TIME);
        }

        public void activate (bool animate, uint animation_time = LONG_ANIMATION_TIME) {
            if (visible || !connected_to_buses) {
                return;
            }

            expand_to_screen_size ();

            if (activation_time == 0) {
                activation_time = GLib.get_monotonic_time ();
            }

#if HAS_MUTTER330
            wm.get_display ().get_cursor_tracker ().set_pointer_visible (false);
#else
            wm.get_screen ().get_cursor_tracker ().set_pointer_visible (false);
#endif

            visible = true;
            grab_key_focus ();
            modal_proxy = wm.push_modal ();

            if (animate) {
                animate_and_lock (animation_time);
            } else {
                _set_active (true);

                if (screensaver_settings.get_boolean (LOCK_ENABLED_KEY)) {
                    @lock (false);
                }
            }
        }

        private void animate_and_lock (uint animation_time) {
            opacity = 0;
            save_easing_state ();
            set_easing_mode (Clutter.AnimationMode.EASE_OUT_QUAD);
            set_easing_duration (animation_time);
            opacity = 255;

            animate_id = Timeout.add (animation_time, () => {
                animate_id = 0;

                restore_easing_state ();

                _set_active (true);

                if (screensaver_settings.get_boolean (LOCK_ENABLED_KEY)) {
                    @lock (false);
                }

                return GLib.Source.REMOVE;
            });
        }

        private void cancel_animation () {
           if (animate_id != 0) {
                GLib.Source.remove (animate_id);
                animate_id = 0;

                restore_easing_state ();
            }
        }

        public void deactivate (bool animate) {
            if (!connected_to_buses) {
                return;
            }

            cancel_animation ();

            is_locked = false;

            if (modal_proxy != null) {
                wm.pop_modal (modal_proxy);
                modal_proxy = null;
            }

#if HAS_MUTTER330
            wm.get_display ().get_cursor_tracker ().set_pointer_visible (true);
#else
            wm.get_screen ().get_cursor_tracker ().set_pointer_visible (true);
#endif

            visible = false;

            wake_up_screen ();

            activation_time = 0;
            _set_active (false);
        }

        private void _set_active (bool new_active) {
            if (!connected_to_buses) {
                return;
            }

            var prev_is_active = active;
            active = new_active;

            if (prev_is_active != active) {
                active_changed ();
            }

            try {
                login_session.set_locked_hint (active);
            } catch (Error e) {
                warning ("Unable to set locked hint on login session: %s", e.message);
            }

            sync_inhibitor ();
        }
    }
}
