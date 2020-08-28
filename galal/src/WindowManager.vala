//
//  Copyright (C) 2012-2014 Tom Beckmann, Rico Tzschichholz
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
    const string DAEMON_DBUS_NAME = "org.pantheon.gala.daemon";
    const string DAEMON_DBUS_OBJECT_PATH = "/org/pantheon/gala/daemon";

    [DBus (name = "org.pantheon.gala.daemon")]
    public interface Daemon: GLib.Object {
        public abstract async void show_window_menu (WindowFlags flags, int x, int y) throws Error;
    }

    public class WindowManagerGala : Meta.Plugin, WindowManager {
        /**
         * {@inheritDoc}
         */
        public Clutter.Actor ui_group { get; protected set; }

        /**
         * {@inheritDoc}
         */
        public Clutter.Stage stage { get; protected set; }

        /**
         * {@inheritDoc}
         */
        public Clutter.Actor window_group { get; protected set; }

        /**
         * {@inheritDoc}
         */
        public Clutter.Actor top_window_group { get; protected set; }

        /**
         * {@inheritDoc}
         */
        public Meta.BackgroundGroup background_group { get; protected set; }

        /**
         * {@inheritDoc}
         */
        public bool enable_animations { get; protected set; }

        public ScreenShield? screen_shield { get; private set; }

        Meta.PluginInfo info;

        WindowSwitcher? winswitcher = null;
        EnsoWindowSwitcher? ensowinswitcher = null;
        ActivatableComponent? workspace_view = null;
        ActivatableComponent? window_overview = null;

        // used to detect which corner was used to trigger an action
        Clutter.Actor? last_hotcorner;
        public ScreenSaverManager? screensaver { get; private set; }

        Clutter.Actor? tile_preview;

        private Meta.Window? moving; //place for the window that is being moved over

        Daemon? daemon_proxy = null;

        NotificationStack notification_stack;

        Gee.LinkedList<ModalProxy> modal_stack = new Gee.LinkedList<ModalProxy> ();

        Gee.HashSet<Meta.WindowActor> minimizing = new Gee.HashSet<Meta.WindowActor> ();
        Gee.HashSet<Meta.WindowActor> maximizing = new Gee.HashSet<Meta.WindowActor> ();
        Gee.HashSet<Meta.WindowActor> unmaximizing = new Gee.HashSet<Meta.WindowActor> ();
        Gee.HashSet<Meta.WindowActor> mapping = new Gee.HashSet<Meta.WindowActor> ();
        Gee.HashSet<Meta.WindowActor> destroying = new Gee.HashSet<Meta.WindowActor> ();
        Gee.HashSet<Meta.WindowActor> unminimizing = new Gee.HashSet<Meta.WindowActor> ();
        GLib.HashTable<Meta.Window, int> ws_assoc = new GLib.HashTable<Meta.Window, int> (direct_hash, direct_equal);
        Meta.SizeChange? which_change = null;
        Meta.Rectangle old_rect_size_change;

        private GLib.Settings animations_settings;
        private GLib.Settings behavior_settings;

        public WindowManagerGala () {
            info = Meta.PluginInfo () {name = "Gala", version = Config.VERSION, author = "Gala Developers",
                license = "GPLv3", description = "A nice elementary window manager"};

#if !HAS_MUTTER332
            Meta.Prefs.set_ignore_request_hide_titlebar (true);
#endif
#if !HAS_MUTTER330
            Meta.Prefs.override_preference_schema ("dynamic-workspaces", Config.SCHEMA + ".behavior");
            Meta.Prefs.override_preference_schema ("attach-modal-dialogs", Config.SCHEMA + ".appearance");
            Meta.Prefs.override_preference_schema ("button-layout", Config.SCHEMA + ".appearance");
            Meta.Prefs.override_preference_schema ("edge-tiling", Config.SCHEMA + ".behavior");
            Meta.Prefs.override_preference_schema ("enable-animations", Config.SCHEMA + ".animations");
#endif
        }

        construct {
            animations_settings = new GLib.Settings (Config.SCHEMA + ".animations");
            animations_settings.bind ("enable-animations", this, "enable-animations", GLib.SettingsBindFlags.GET);
            behavior_settings = new GLib.Settings (Config.SCHEMA + ".behavior");
            enable_animations = animations_settings.get_boolean ("enable-animations");
        }

        public override void start () {
            Meta.Util.later_add (Meta.LaterType.BEFORE_REDRAW, show_stage);

            Bus.watch_name (BusType.SESSION, DAEMON_DBUS_NAME, BusNameWatcherFlags.NONE, daemon_appeared, lost_daemon);

#if HAS_MUTTER330
            unowned Meta.Display display = get_display ();
#else
            unowned Meta.Display display = get_screen ().get_display ();
#endif
            display.gl_video_memory_purged.connect (() => {
                Meta.Background.refresh_all ();
                SystemBackground.refresh ();
            });
        }

        void on_menu_get (GLib.Object? o, GLib.AsyncResult? res) {
            try {
                daemon_proxy = Bus.get_proxy.end (res);
            } catch (Error e) {
                warning ("Failed to get Menu proxy: %s", e.message);
            }
        }

        void lost_daemon () {
            daemon_proxy = null;
        }

        void daemon_appeared () {
            if (daemon_proxy == null) {
                Bus.get_proxy.begin<Daemon> (BusType.SESSION, DAEMON_DBUS_NAME, DAEMON_DBUS_OBJECT_PATH, 0, null, on_menu_get);
            }
        }

        bool show_stage () {
#if HAS_MUTTER330
            unowned Meta.Display display = get_display ();
#else
            var screen = get_screen ();
            var display = screen.get_display ();
#endif

            screen_shield = new ScreenShield (this);
            screensaver = new ScreenSaverManager (screen_shield);

            DBus.init (this);
            DBusAccelerator.init (this);
            MediaFeedback.init ();
#if HAS_MUTTER330
            WindowListener.init (display);
#else
            WindowListener.init (screen);
#endif
            KeyboardManager.init (display);

#if HAS_MUTTER330
            notification_stack = new NotificationStack (display);
#else
            notification_stack = new NotificationStack (screen);
#endif

            // Due to a bug which enables access to the stage when using multiple monitors
            // in the screensaver, we have to listen for changes and make sure the input area
            // is set to NONE when we are in locked mode
            screensaver.active_changed.connect (update_input_area);

#if HAS_MUTTER330
            stage = display.get_stage () as Clutter.Stage;
#else
            stage = screen.get_stage () as Clutter.Stage;
#endif
            var background_settings = new GLib.Settings ("org.gnome.desktop.background");
            var color = background_settings.get_string ("primary-color");
            stage.background_color = Clutter.Color.from_string (color);

            WorkspaceManager.init (this);

            /* our layer structure, copied from gnome-shell (from bottom to top):
             * stage
             * + system background
             * + ui group
             * +-- window group
             * +---- background manager
             * +-- shell elements
             * +-- top window group
             */

#if HAS_MUTTER330
            var system_background = new SystemBackground (display);
#else
            var system_background = new SystemBackground (screen);
#endif

#if HAS_MUTTER332
            system_background.background_actor.add_constraint (new Clutter.BindConstraint (stage,
                Clutter.BindCoordinate.ALL, 0));
            stage.insert_child_below (system_background.background_actor, null);
#else
            system_background.add_constraint (new Clutter.BindConstraint (stage,
                Clutter.BindCoordinate.ALL, 0));
            stage.insert_child_below (system_background, null);
#endif

            ui_group = new Clutter.Actor ();
            ui_group.reactive = true;
            stage.add_child (ui_group);

#if HAS_MUTTER330
            window_group = display.get_window_group ();
#else
            window_group = screen.get_window_group ();
#endif
            stage.remove_child (window_group);
            ui_group.add_child (window_group);

#if HAS_MUTTER330
            background_group = new BackgroundContainer (display);
            background_group.set_reactive(true);
			background_group.button_release_event.connect(on_background_click);
#else
            background_group = new BackgroundContainer (screen);
            background_group.set_reactive(true);
			background_group.button_release_event.connect(on_background_click);
#endif
            window_group.add_child (background_group);
            window_group.set_child_below_sibling (background_group, null);

#if HAS_MUTTER330
            top_window_group = display.get_top_window_group ();
#else
            top_window_group = screen.get_top_window_group ();
#endif
            ui_group.add_child (screen_shield);

            stage.remove_child (top_window_group);
            ui_group.add_child (top_window_group);

            /*keybindings*/
            var keybinding_settings = new GLib.Settings (Config.SCHEMA + ".keybindings");

            display.add_keybinding ("switch-to-workspace-first", keybinding_settings, 0, (Meta.KeyHandlerFunc) handle_switch_to_workspace_end);
            display.add_keybinding ("switch-to-workspace-last", keybinding_settings, 0, (Meta.KeyHandlerFunc) handle_switch_to_workspace_end);
            display.add_keybinding ("move-to-workspace-first", keybinding_settings, 0, (Meta.KeyHandlerFunc) handle_move_to_workspace_end);
            display.add_keybinding ("move-to-workspace-last", keybinding_settings, 0, (Meta.KeyHandlerFunc) handle_move_to_workspace_end);
            display.add_keybinding ("cycle-workspaces-next", keybinding_settings, 0, (Meta.KeyHandlerFunc) handle_cycle_workspaces);
            display.add_keybinding ("cycle-workspaces-previous", keybinding_settings, 0, (Meta.KeyHandlerFunc) handle_cycle_workspaces);

            display.overlay_key.connect (() => {
                try {
                    Process.spawn_command_line_async (
                        behavior_settings.get_string ("overlay-action")
                    );
                } catch (Error e) { warning (e.message); }
            });

            Meta.KeyBinding.set_custom_handler ("panel-main-menu", () => {
                try {
                    Process.spawn_command_line_async (
                        behavior_settings.get_string ("panel-main-menu-action")
                    );
                } catch (Error e) { warning (e.message); }
            });

            Meta.KeyBinding.set_custom_handler ("toggle-recording", () => {
                try {
                    Process.spawn_command_line_async (
                        behavior_settings.get_string ("toggle-recording-action")
                    );
                } catch (Error e) { warning (e.message); }
            });

            Meta.KeyBinding.set_custom_handler ("switch-to-workspace-up", () => {});
            Meta.KeyBinding.set_custom_handler ("switch-to-workspace-down", () => {});
            Meta.KeyBinding.set_custom_handler ("switch-to-workspace-left", (Meta.KeyHandlerFunc) handle_switch_to_workspace);
            Meta.KeyBinding.set_custom_handler ("switch-to-workspace-right", (Meta.KeyHandlerFunc) handle_switch_to_workspace);

            Meta.KeyBinding.set_custom_handler ("move-to-workspace-up", () => {});
            Meta.KeyBinding.set_custom_handler ("move-to-workspace-down", () => {});
            Meta.KeyBinding.set_custom_handler ("move-to-workspace-left", (Meta.KeyHandlerFunc) handle_move_to_workspace);
            Meta.KeyBinding.set_custom_handler ("move-to-workspace-right", (Meta.KeyHandlerFunc) handle_move_to_workspace);

            Meta.KeyBinding.set_custom_handler ("switch-group", () => {});
            Meta.KeyBinding.set_custom_handler ("switch-group-backward", () => {});

            /*shadows*/
            InternalUtils.reload_shadow ();
            ShadowSettings.get_default ().notify.connect (InternalUtils.reload_shadow);

            /*hot corner, getting enum values from GraniteServicesSettings did not work, so we use GSettings directly*/
            configure_hotcorners ();
#if HAS_MUTTER330
            Meta.MonitorManager.@get ().monitors_changed.connect (on_monitors_changed);
#else
            screen.monitors_changed.connect (on_monitors_changed);
#endif

            behavior_settings.changed.connect (configure_hotcorners);

            // initialize plugins and add default components if no plugin overrides them
            var plugin_manager = PluginManager.get_default ();
            plugin_manager.initialize (this);
            plugin_manager.regions_changed.connect (update_input_area);

            if (plugin_manager.workspace_view_provider == null
                || (workspace_view = (plugin_manager.get_plugin (plugin_manager.workspace_view_provider) as ActivatableComponent)) == null) {
                workspace_view = new MultitaskingView (this);
                ui_group.add_child ((Clutter.Actor) workspace_view);
            }

            Meta.KeyBinding.set_custom_handler ("show-desktop", () => {
                if (workspace_view.is_opened ())
                    workspace_view.close ();
                else
                    workspace_view.open ();
            });

            if (plugin_manager.window_switcher_provider == null) {
                ensowinswitcher = new EnsoWindowSwitcher (this);
                ui_group.add_child (ensowinswitcher);

                Meta.KeyBinding.set_custom_handler ("switch-applications", (Meta.KeyHandlerFunc) ensowinswitcher.handle_switch_windows);
                Meta.KeyBinding.set_custom_handler ("switch-applications-backward", (Meta.KeyHandlerFunc) ensowinswitcher.handle_switch_windows);
                Meta.KeyBinding.set_custom_handler ("switch-windows", (Meta.KeyHandlerFunc) ensowinswitcher.handle_switch_windows);
                Meta.KeyBinding.set_custom_handler ("switch-windows-backward", (Meta.KeyHandlerFunc) ensowinswitcher.handle_switch_windows);
            }

            if (plugin_manager.window_overview_provider == null
                || (window_overview = (plugin_manager.get_plugin (plugin_manager.window_overview_provider) as ActivatableComponent)) == null) {
                window_overview = new WindowOverview (this);
                ui_group.add_child ((Clutter.Actor) window_overview);
            }

            display.add_keybinding ("expose-windows", keybinding_settings, 0, () => {
                if (window_overview.is_opened ())
                    window_overview.close ();
                else
                    window_overview.open ();
            });
            display.add_keybinding ("expose-all-windows", keybinding_settings, 0, () => {
                if (window_overview.is_opened ())
                    window_overview.close ();
                else {
                    var hints = new HashTable<string,Variant> (str_hash, str_equal);
                    hints.@set ("all-windows", true);
                    window_overview.open (hints);
                }
            });

            update_input_area ();

            stage.show ();

            // let the session manager move to the next phase
            Meta.register_with_session ();

            Idle.add (() => {
                plugin_manager.load_waiting_plugins ();
                return false;
            });

            return false;
        }

        /**
         * Launch menu manager with our wallpaper
         */

        DesktopMenu desktop_menu = null;

        private bool on_background_click(Clutter.ButtonEvent? event)
        {
            if(event.button == 3)
            {
#if HAS_MUTTER330
                var time = get_display ().get_current_time_roundtrip ();
#else 
                var time = get_screen ().get_display ().get_current_time_roundtrip ();
#endif
                if(desktop_menu == null)
                    desktop_menu = new DesktopMenu (this);
                    //get_current_cursor_position(out x, out y);
                    desktop_menu.show_all ();

                    desktop_menu.popup (null, null, null, Gdk.BUTTON_SECONDARY, time);

            }
            return true;
        }

        void on_monitors_changed () {
            configure_hotcorners ();
            screen_shield.expand_to_screen_size ();
        }

        void configure_hotcorners () {
#if HAS_MUTTER330
            unowned Meta.Display display = get_display ();
            var geometry = display.get_monitor_geometry (display.get_primary_monitor ());
#else
            var geometry = get_screen ().get_monitor_geometry (get_screen ().get_primary_monitor ());
#endif

            add_hotcorner (geometry.x, geometry.y, "hotcorner-topleft");
            add_hotcorner (geometry.x + geometry.width - 1, geometry.y, "hotcorner-topright");
            add_hotcorner (geometry.x, geometry.y + geometry.height - 1, "hotcorner-bottomleft");
            add_hotcorner (geometry.x + geometry.width - 1, geometry.y + geometry.height - 1, "hotcorner-bottomright");

            update_input_area ();
        }

        void add_hotcorner (float x, float y, string key) {
#if HAS_MUTTER330
            unowned Clutter.Actor? stage = get_display ().get_stage ();
#else
            unowned Clutter.Actor? stage = get_screen ().get_stage ();
#endif
            return_if_fail (stage != null);

            var action = (ActionType) behavior_settings.get_enum (key);
            Clutter.Actor? hot_corner = stage.find_child_by_name (key);

            if (action == ActionType.NONE) {
                if (hot_corner != null)
                    stage.remove_child (hot_corner);
                return;
            }

            // if the hot corner already exists, just reposition it, create it otherwise
            if (hot_corner == null) {
                hot_corner = new Clutter.Actor ();
                hot_corner.width = 1;
                hot_corner.height = 1;
                hot_corner.opacity = 0;
                hot_corner.reactive = true;
                hot_corner.name = key;

                stage.add_child (hot_corner);

                hot_corner.enter_event.connect ((actor, event) => {
                    last_hotcorner = actor;
                    perform_action ((ActionType) behavior_settings.get_enum (actor.name));
                    return false;
                });
            }

            hot_corner.x = x;
            hot_corner.y = y;
        }

#if HAS_MUTTER330
        [CCode (instance_pos = -1)]
        void handle_cycle_workspaces (Meta.Display display, Meta.Window? window, Clutter.KeyEvent event,
            Meta.KeyBinding binding) {
            var direction = (binding.get_name () == "cycle-workspaces-next" ? 1 : -1);
            unowned Meta.WorkspaceManager manager = display.get_workspace_manager ();
            var index = manager.get_active_workspace_index () + direction;

            int dynamic_offset = Meta.Prefs.get_dynamic_workspaces () ? 1 : 0;

            if (index < 0)
                index = manager.get_n_workspaces () - 1 - dynamic_offset;
            else if (index > manager.get_n_workspaces () - 1 - dynamic_offset)
                index = 0;

            manager.get_workspace_by_index (index).activate (display.get_current_time ());
        }

        [CCode (instance_pos = -1)]
        void handle_move_to_workspace (Meta.Display display, Meta.Window? window,
            Clutter.KeyEvent event, Meta.KeyBinding binding) {
            if (window == null)
                return;

            var direction = (binding.get_name () == "move-to-workspace-left" ? Meta.MotionDirection.UP : Meta.MotionDirection.DOWN);
            move_window (window, direction);
        }

        [CCode (instance_pos = -1)]
        void handle_move_to_workspace_end (Meta.Display display, Meta.Window? window,
            Clutter.KeyEvent event, Meta.KeyBinding binding) {
            if (window == null)
                return;

            unowned Meta.WorkspaceManager manager = display.get_workspace_manager ();
            var index = (binding.get_name () == "move-to-workspace-first" ? 0 : manager.get_n_workspaces () - 1);
            var workspace = manager.get_workspace_by_index (index);
            window.change_workspace (workspace);
            workspace.activate_with_focus (window, display.get_current_time ());
        }

        [CCode (instance_pos = -1)]
        void handle_switch_to_workspace (Meta.Display display, Meta.Window? window,
            Clutter.KeyEvent event, Meta.KeyBinding binding) {
            var direction = (binding.get_name () == "switch-to-workspace-left" ? Meta.MotionDirection.UP : Meta.MotionDirection.DOWN);
            switch_to_next_workspace (direction);
        }

        [CCode (instance_pos = -1)]
        void handle_switch_to_workspace_end (Meta.Display display, Meta.Window? window,
            Clutter.KeyEvent event, Meta.KeyBinding binding) {
            unowned Meta.WorkspaceManager manager = display.get_workspace_manager ();
            var index = (binding.get_name () == "switch-to-workspace-first" ? 0 : manager.n_workspaces - 1);
            manager.get_workspace_by_index (index).activate (display.get_current_time ());
        }
#else
        [CCode (instance_pos = -1)]
        void handle_cycle_workspaces (Meta.Display display, Meta.Screen screen, Meta.Window? window,
            Clutter.KeyEvent event, Meta.KeyBinding binding) {
            var direction = (binding.get_name () == "cycle-workspaces-next" ? 1 : -1);
            var index = screen.get_active_workspace_index () + direction;

            int dynamic_offset = Meta.Prefs.get_dynamic_workspaces () ? 1 : 0;

            if (index < 0)
                index = screen.get_n_workspaces () - 1 - dynamic_offset;
            else if (index > screen.get_n_workspaces () - 1 - dynamic_offset)
                index = 0;

            screen.get_workspace_by_index (index).activate (display.get_current_time ());
        }

        [CCode (instance_pos = -1)]
        void handle_move_to_workspace (Meta.Display display, Meta.Screen screen, Meta.Window? window,
            Clutter.KeyEvent event, Meta.KeyBinding binding) {
            if (window == null)
                return;

            var direction = (binding.get_name () == "move-to-workspace-left" ? Meta.MotionDirection.UP : Meta.MotionDirection.DOWN);
            move_window (window, direction);
        }

        [CCode (instance_pos = -1)]
        void handle_move_to_workspace_end (Meta.Display display, Meta.Screen screen, Meta.Window? window,
            Clutter.KeyEvent event, Meta.KeyBinding binding) {
            if (window == null)
                return;

            var index = (binding.get_name () == "move-to-workspace-first" ? 0 : screen.get_n_workspaces () - 1);
            var workspace = screen.get_workspace_by_index (index);
            window.change_workspace (workspace);
            workspace.activate_with_focus (window, display.get_current_time ());
        }

        [CCode (instance_pos = -1)]
        void handle_switch_to_workspace (Meta.Display display, Meta.Screen screen, Meta.Window? window,
            Clutter.KeyEvent event, Meta.KeyBinding binding) {
            var direction = (binding.get_name () == "switch-to-workspace-left" ? Meta.MotionDirection.UP : Meta.MotionDirection.DOWN);
            switch_to_next_workspace (direction);
        }

        [CCode (instance_pos = -1)]
        void handle_switch_to_workspace_end (Meta.Display display, Meta.Screen screen, Meta.Window? window,
            Clutter.KeyEvent event, Meta.KeyBinding binding) {
            var index = (binding.get_name () == "switch-to-workspace-first" ? 0 : screen.n_workspaces - 1);
            screen.get_workspace_by_index (index).activate (display.get_current_time ());
        }
#endif

        /**
         * {@inheritDoc}
         */
        public void switch_to_next_workspace (Meta.MotionDirection direction) {
            Meta.Workspace neighbor = null;
#if HAS_MUTTER330
            unowned Meta.Display display = get_display ();
            var active_workspace = display.get_workspace_manager ().get_active_workspace ();
#else
            var screen = get_screen ();
            var display = screen.get_display ();
            var active_workspace = screen.get_active_workspace ();
#endif
            neighbor = active_workspace.get_neighbor (direction);
            
            if (neighbor != active_workspace) {
                neighbor.activate (display.get_current_time ());
                return;
            }

            // if we didnt switch, show a nudge-over animation if one is not already in progress
            if (ui_group.get_transition ("nudge") != null)
                return;

            var dest = (direction == Meta.MotionDirection.UP ? 32.0f : -32.0f);

            double[] keyframes = { 0.28, 0.58 };
            GLib.Value[] x = { dest, dest };

            var nudge = new Clutter.KeyframeTransition ("x");
            nudge.duration = 360;
            nudge.remove_on_complete = true;
            nudge.progress_mode = Clutter.AnimationMode.LINEAR;
            nudge.set_from_value (0.0f);
            nudge.set_to_value (0.0f);
            nudge.set_key_frames (keyframes);
            nudge.set_values (x);

            ui_group.add_transition ("nudge", nudge);
        }

#if HAS_MUTTER330
        void update_input_area () {
            unowned Meta.Display display = get_display ();

            if (screensaver != null) {
                try {
                    if (screensaver.get_active ()) {
                        InternalUtils.set_input_area (display, InputArea.NONE);
                        return;
                    }
                } catch (Error e) {
                    // the screensaver object apparently won't be null even though
                    // it is unavailable. This error will be thrown however, so we
                    // can just ignore it, because if it is thrown, the screensaver
                    // is unavailable.
                }
            }

            if (is_modal ())
                InternalUtils.set_input_area (display, InputArea.FULLSCREEN);
            else
                InternalUtils.set_input_area (display, InputArea.DEFAULT);
        }
#else
        void update_input_area () {
            var screen = get_screen ();

            if (screensaver != null) {
                try {
                    if (screensaver.get_active ()) {
                        InternalUtils.set_input_area (screen, InputArea.NONE);
                        return;
                    }
                } catch (Error e) {
                    // the screensaver object apparently won't be null even though
                    // it is unavailable. This error will be thrown however, so we
                    // can just ignore it, because if it is thrown, the screensaver
                    // is unavailable.
                }
            }

            if (is_modal ())
                InternalUtils.set_input_area (screen, InputArea.FULLSCREEN);
            else
                InternalUtils.set_input_area (screen, InputArea.DEFAULT);
        }
#endif

        void show_bottom_stack_window (Meta.Window bottom_window) {
            unowned Meta.Workspace workspace = bottom_window.get_workspace ();
            if (Utils.get_n_windows (workspace) == 0) {
                return;
            }

            var bottom_actor = bottom_window.get_compositor_private () as Meta.WindowActor;
            if (enable_animations) {
                animate_bottom_window_scale (bottom_actor);
            }

            uint fade_out_duration = 900U;
            double[] op_keyframes = { 0.1, 0.9 };
            GLib.Value[] opacity = { 20U, 20U };

            workspace.list_windows ().@foreach ((window) => {
                if (window.get_xwindow () == bottom_window.get_xwindow ()
                    || !InternalUtils.get_window_is_normal (window)
                    || window.minimized) {
                    return;
                }

                var actor = window.get_compositor_private () as Clutter.Actor;
                if (enable_animations) {
                    var op_trans = new Clutter.KeyframeTransition ("opacity");
                    op_trans.duration = fade_out_duration;
                    op_trans.remove_on_complete = true;
                    op_trans.progress_mode = Clutter.AnimationMode.EASE_IN_OUT_QUAD;
                    op_trans.set_from_value (255.0f);
                    op_trans.set_to_value (255.0f);
                    op_trans.set_key_frames (op_keyframes);
                    op_trans.set_values (opacity);

                    actor.add_transition ("opacity-hide", op_trans);
                } else {
                    Timeout.add ((uint)(fade_out_duration * op_keyframes[0]), () => {
                        actor.opacity = (uint)opacity[0];
                        return false;
                    });

                    Timeout.add ((uint)(fade_out_duration * op_keyframes[1]), () => {
                        actor.opacity = 255U;
                        return false;
                    });
                }
            });
        }

        void animate_bottom_window_scale (Meta.WindowActor actor) {
            const string[] props = { "scale-x", "scale-y" };

            foreach (string prop in props) {
                double[] scale_keyframes = { 0.2, 0.3, 0.8 };
                GLib.Value[] scale = { 1.0f, 1.07f, 1.07f };

                var scale_trans = new Clutter.KeyframeTransition (prop);
                scale_trans.duration = 500;
                scale_trans.remove_on_complete = true;
                scale_trans.progress_mode = Clutter.AnimationMode.EASE_IN_QUAD;
                scale_trans.set_from_value (1.0f);
                scale_trans.set_to_value (1.0f);
                scale_trans.set_key_frames (scale_keyframes);
                scale_trans.set_values (scale);

                actor.add_transition ("magnify-%s".printf (prop), scale_trans);
            }
        }

        public uint32[] get_all_xids () {
            var list = new Gee.ArrayList<uint32> ();

#if HAS_MUTTER330
            unowned Meta.Display display = get_display ();
            unowned Meta.WorkspaceManager manager = display.get_workspace_manager ();
            for (int i = 0; i < manager.get_n_workspaces (); i++) {
                foreach (var window in manager.get_workspace_by_index (i).list_windows ())
                    list.add ((uint32)window.get_xwindow ());
            }
#else
            unowned GLib.List<Meta.Workspace> workspaces = get_screen ().get_workspaces ();
            foreach (var workspace in workspaces) {
                foreach (var window in workspace.list_windows ())
                    list.add ((uint32)window.get_xwindow ());
            }
#endif

            return list.to_array ();
        }

        /**
         * {@inheritDoc}
         */
        public void move_window (Meta.Window? window, Meta.MotionDirection direction) {
            if (window == null)
                return;

#if HAS_MUTTER330
            unowned Meta.Display display = get_display ();
            unowned Meta.WorkspaceManager manager = display.get_workspace_manager ();

            var active = manager.get_active_workspace ();
            var next = active.get_neighbor (direction);

            //dont allow empty workspaces to be created by moving, if we have dynamic workspaces
            if (Meta.Prefs.get_dynamic_workspaces () && Utils.get_n_windows (active) == 1 && next.index () == manager.n_workspaces - 1) {
                Utils.bell (display);
                return;
            }
#else
            var screen = get_screen ();
            var display = screen.get_display ();

            var active = screen.get_active_workspace ();
            var next = active.get_neighbor (direction);

            //dont allow empty workspaces to be created by moving, if we have dynamic workspaces
            if ((Meta.Prefs.get_dynamic_workspaces () && Utils.get_n_windows (active) == 1 && next.index () == screen.n_workspaces - 1)
                || (active == next)) {
                Utils.bell (screen);
                return;
            }
#endif

            moving = window;

            if (!window.is_on_all_workspaces ())
                window.change_workspace (next);

            next.activate_with_focus (window, display.get_current_time ());
        }

        /**
         * {@inheritDoc}
         */
        public ModalProxy push_modal () {
            var proxy = new ModalProxy ();

            modal_stack.offer_head (proxy);

            // modal already active
            if (modal_stack.size >= 2)
                return proxy;

#if HAS_MUTTER330
            unowned Meta.Display display = get_display ();
            var time = display.get_current_time ();
#else
            var screen = get_screen ();
            var time = screen.get_display ().get_current_time ();
#endif

            update_input_area ();
            begin_modal (0, time);

#if HAS_MUTTER330
            display.disable_unredirect ();
#else
            screen.disable_unredirect ();
#endif

            return proxy;
        }

        /**
         * {@inheritDoc}
         */
        public void pop_modal (ModalProxy proxy) {
            if (!modal_stack.remove (proxy)) {
                warning ("Attempted to remove a modal proxy that was not in the stack");
                return;
            }

            if (is_modal ())
                return;

            update_input_area ();

#if HAS_MUTTER330
            unowned Meta.Display display = get_display ();
            end_modal (display.get_current_time ());

            display.enable_unredirect ();
#else
            var screen = get_screen ();
            end_modal (screen.get_display ().get_current_time ());

            screen.enable_unredirect ();
#endif
        }

        /**
         * {@inheritDoc}
         */
        public bool is_modal () {
            return (modal_stack.size > 0);
        }

        /**
         * {@inheritDoc}
         */
        public bool modal_proxy_valid (ModalProxy proxy) {
            return (proxy in modal_stack);
        }

        public void get_current_cursor_position (out int x, out int y) {
            Gdk.Display.get_default ().get_device_manager ().get_client_pointer ().get_position (null,
                out x, out y);
        }

        public void dim_window (Meta.Window window, bool dim) {
            /*FIXME we need a super awesome blureffect here, the one from clutter is just... bah!
            var win = window.get_compositor_private () as Meta.WindowActor;
            if (dim) {
                if (win.has_effects ())
                    return;
                win.add_effect_with_name ("darken", new Clutter.BlurEffect ());
            } else
                win.clear_effects ();*/
        }

        /**
         * {@inheritDoc}
         */
        public void perform_action (ActionType type) {
#if HAS_MUTTER330
            unowned Meta.Display display = get_display ();
            var current = display.get_focus_window ();
#else
            var screen = get_screen ();
            var display = screen.get_display ();
            var current = display.get_focus_window ();
#endif

            switch (type) {
                case ActionType.SHOW_WORKSPACE_VIEW:
                    if (workspace_view == null)
                        break;

                    if (workspace_view.is_opened ())
                        workspace_view.close ();
                    else
                        workspace_view.open ();
                    break;
                case ActionType.MAXIMIZE_CURRENT:
                    if (current == null || current.window_type != Meta.WindowType.NORMAL)
                        break;

                    if (current.get_maximized () == (Meta.MaximizeFlags.HORIZONTAL | Meta.MaximizeFlags.VERTICAL))
                        current.unmaximize (Meta.MaximizeFlags.HORIZONTAL | Meta.MaximizeFlags.VERTICAL);
                    else
                        current.maximize (Meta.MaximizeFlags.HORIZONTAL | Meta.MaximizeFlags.VERTICAL);
                    break;
                case ActionType.MINIMIZE_CURRENT:
                    if (current != null && current.window_type == Meta.WindowType.NORMAL)
                        current.minimize ();
                    break;
                case ActionType.START_MOVE_CURRENT:
                    if (current != null && current.allows_move ())
                        current.begin_grab_op (Meta.GrabOp.KEYBOARD_MOVING, true, Gtk.get_current_event_time ());
                    break;
                case ActionType.START_RESIZE_CURRENT:
                    if (current != null && current.allows_resize ())
                        current.begin_grab_op (Meta.GrabOp.KEYBOARD_RESIZING_UNKNOWN, true, Gtk.get_current_event_time ());
                    break;
                case ActionType.TOGGLE_ALWAYS_ON_TOP_CURRENT:
                    if (current == null)
                        break;

                    if (current.is_above ())
                        current.unmake_above ();
                    else
                        current.make_above ();
                    break;
                case ActionType.TOGGLE_ALWAYS_ON_VISIBLE_WORKSPACE_CURRENT:
                    if (current == null)
                        break;

                    if (current.on_all_workspaces)
                        current.unstick ();
                    else
                        current.stick ();
                    break;
                case ActionType.MOVE_CURRENT_WORKSPACE_LEFT:
                    if (current != null) {
                        var wp = current.get_workspace ().get_neighbor (Meta.MotionDirection.UP);
                        if (wp != null)
                            current.change_workspace (wp);
                    }
                    break;
                case ActionType.MOVE_CURRENT_WORKSPACE_RIGHT:
                    if (current != null) {
                        var wp = current.get_workspace ().get_neighbor (Meta.MotionDirection.DOWN);
                        if (wp != null)
                            current.change_workspace (wp);
                    }
                    break;
                case ActionType.CLOSE_CURRENT:
                    if (current != null && current.can_close ())
                        current.@delete (Gtk.get_current_event_time ());
                    break;
                case ActionType.OPEN_LAUNCHER:
                    try {
                        Process.spawn_command_line_async (
                            behavior_settings.get_string ("panel-main-menu-action")
                        );
                    } catch (Error e) {
                        warning (e.message);
                    }
                    break;
                case ActionType.CUSTOM_COMMAND:
                    string command = "";
                    var line = behavior_settings.get_string ("hotcorner-custom-command");
                    if (line == "")
                        return;

                    var parts = line.split (";;");
                    // keep compatibility to old version where only one command was possible
                    if (parts.length == 1) {
                        command = line;
                    } else {
                        // find specific actions
                        var search = last_hotcorner.name;

                        foreach (var part in parts) {
                            var details = part.split (":");
                            if (details[0] == search) {
                                command = details[1];
                            }
                        }
                    }

                    try {
                        Process.spawn_command_line_async (command);
                    } catch (Error e) {
                        warning (e.message);
                    }
                    break;
                case ActionType.WINDOW_OVERVIEW:
                    if (window_overview == null)
                        break;

                    if (window_overview.is_opened ())
                        window_overview.close ();
                    else
                        window_overview.open ();
                    break;
                case ActionType.WINDOW_OVERVIEW_ALL:
                    if (window_overview == null)
                        break;

                    if (window_overview.is_opened ())
                        window_overview.close ();
                    else {
                        var hints = new HashTable<string,Variant> (str_hash, str_equal);
                        hints.@set ("all-windows", true);
                        window_overview.open (hints);
                    }
                    break;
                case ActionType.SWITCH_TO_WORKSPACE_LAST:
#if HAS_MUTTER330
                    unowned Meta.WorkspaceManager manager = display.get_workspace_manager ();
                    var workspace = manager.get_workspace_by_index (manager.get_n_workspaces () - 1);
#else
                    var workspace = screen.get_workspace_by_index (screen.get_n_workspaces () - 1);
#endif
                    workspace.activate (display.get_current_time ());
                    break;
                default:
                    warning ("Trying to run unknown action");
                    break;
            }
        }

        public override void show_window_menu (Meta.Window window, Meta.WindowMenuType menu, int x, int y) {
            switch (menu) {
                case Meta.WindowMenuType.WM:
                    if (daemon_proxy == null || window.get_window_type () == Meta.WindowType.NOTIFICATION) {
                        return;
                    }

                    WindowFlags flags = WindowFlags.NONE;
                    if (window.can_minimize ())
                        flags |= WindowFlags.CAN_MINIMIZE;

                    if (window.can_maximize ())
                        flags |= WindowFlags.CAN_MAXIMIZE;

                    if (window.get_maximized () > 0)
                        flags |= WindowFlags.IS_MAXIMIZED;

                    if (window.allows_move ())
                        flags |= WindowFlags.ALLOWS_MOVE;

                    if (window.allows_resize ())
                        flags |= WindowFlags.ALLOWS_RESIZE;

                    if (window.is_above ())
                        flags |= WindowFlags.ALWAYS_ON_TOP;

                    if (window.on_all_workspaces)
                        flags |= WindowFlags.ON_ALL_WORKSPACES;

                    if (window.can_close ())
                        flags |= WindowFlags.CAN_CLOSE;

                    try {
                        daemon_proxy.show_window_menu.begin (flags, x, y);
                    } catch (Error e) {
                        message ("Error invoking MenuManager: %s", e.message);
                    }
                    break;
                case Meta.WindowMenuType.APP:
                    // FIXME we don't have any sort of app menus
                    break;
            }
        }

        public override void show_tile_preview (Meta.Window window, Meta.Rectangle tile_rect, int tile_monitor_number) {
            if (tile_preview == null) {
                tile_preview = new Clutter.Actor ();
                tile_preview.background_color = { 100, 186, 255, 100 };
                tile_preview.opacity = 0U;

                window_group.add_child (tile_preview);
            } else if (tile_preview.is_visible ()) {
                float width, height, x, y;
                tile_preview.get_position (out x, out y);
                tile_preview.get_size (out width, out height);

                if ((tile_rect.width == width && tile_rect.height == height && tile_rect.x == x && tile_rect.y == y)
                    || tile_preview.get_transition ("size") != null) {
                    return;
                }
            }

            unowned Meta.WindowActor window_actor = window.get_compositor_private () as Meta.WindowActor;
            window_group.set_child_below_sibling (tile_preview, window_actor);

            var duration = AnimationDuration.SNAP / 2U;

            var rect = window.get_frame_rect ();
            tile_preview.set_position (rect.x, rect.y);
            tile_preview.set_size (rect.width, rect.height);
            tile_preview.show ();

            if (enable_animations) {
                tile_preview.save_easing_state ();
                tile_preview.set_easing_mode (Clutter.AnimationMode.EASE_IN_OUT_QUAD);
                tile_preview.set_easing_duration (duration);
                tile_preview.opacity = 255U;
                tile_preview.set_position (tile_rect.x, tile_rect.y);
                tile_preview.set_size (tile_rect.width, tile_rect.height);
                tile_preview.restore_easing_state ();
            } else {
                tile_preview.opacity = 255U;
            }
        }

        public override void hide_tile_preview () {
            if (tile_preview != null) {
                tile_preview.remove_all_transitions ();
                tile_preview.opacity = 0U;
                tile_preview.hide ();
            }
        }

        public override void show_window_menu_for_rect (Meta.Window window, Meta.WindowMenuType menu, Meta.Rectangle rect) {
            show_window_menu (window, menu, rect.x, rect.y);
        }

        /*
         * effects
         */

        void handle_fullscreen_window (Meta.Window window, Meta.SizeChange which_change) {
            // Only handle windows which are located on the primary monitor
            if (!window.is_on_primary_monitor ())
                return;

            // Due to how this is implemented, by relying on the functionality
            // offered by the dynamic workspace handler, let's just bail out
            // if that's not available.
            if (!Meta.Prefs.get_dynamic_workspaces ())
                return;

#if HAS_MUTTER330
            unowned Meta.Display display = get_display ();
            var time = display.get_current_time ();
            unowned Meta.Workspace win_ws = window.get_workspace ();
            unowned Meta.WorkspaceManager manager = display.get_workspace_manager ();

            if (which_change == Meta.SizeChange.FULLSCREEN) {
                // Do nothing if the current workspace would be empty
                if (Utils.get_n_windows (win_ws) <= 1)
                    return;

                var old_ws_index = win_ws.index ();
                var new_ws_index = old_ws_index + 1;
                InternalUtils.insert_workspace_with_window (new_ws_index, window);

                var new_ws_obj = manager.get_workspace_by_index (new_ws_index);
                window.change_workspace (new_ws_obj);
                new_ws_obj.activate_with_focus (window, time);

                ws_assoc.insert (window, old_ws_index);
            } else if (ws_assoc.contains (window)) {
                var old_ws_index = ws_assoc.get (window);
                var new_ws_index = win_ws.index ();

                if (new_ws_index != old_ws_index && old_ws_index < manager.get_n_workspaces ()) {
                    var old_ws_obj = manager.get_workspace_by_index (old_ws_index);
                    window.change_workspace (old_ws_obj);
                    old_ws_obj.activate_with_focus (window, time);
                }

                ws_assoc.remove (window);
            }
#else
            unowned Meta.Screen screen = get_screen ();
            var time = screen.get_display ().get_current_time ();
            unowned Meta.Workspace win_ws = window.get_workspace ();

            if (which_change == Meta.SizeChange.FULLSCREEN) {
                // Do nothing if the current workspace would be empty
                if (Utils.get_n_windows (win_ws) <= 1)
                    return;

                var old_ws_index = win_ws.index ();
                var new_ws_index = old_ws_index + 1;
                InternalUtils.insert_workspace_with_window (new_ws_index, window);

                var new_ws_obj = screen.get_workspace_by_index (new_ws_index);
                window.change_workspace (new_ws_obj);
                new_ws_obj.activate_with_focus (window, time);

                ws_assoc.insert (window, old_ws_index);
            } else {
                move_window_to_old_ws (window);
            }
#endif
        }

        // must wait for size_changed to get updated frame_rect
        // as which_change is not passed to size_changed, save it as instance variable
        public override void size_change (Meta.WindowActor actor, Meta.SizeChange which_change_local, Meta.Rectangle old_frame_rect, Meta.Rectangle old_buffer_rect) {
            which_change = which_change_local;
            old_rect_size_change = old_frame_rect;
        }

        // size_changed gets called after frame_rect has updated
        public override void size_changed (Meta.WindowActor actor) {
            if (which_change == null) {
                return;
            }

            Meta.SizeChange? which_change_local = which_change;
            which_change = null;

            unowned Meta.Window window = actor.get_meta_window ();
            var new_rect = window.get_frame_rect ();

            switch (which_change_local) {
                case Meta.SizeChange.MAXIMIZE:
                    // don't animate resizing of two tiled windows with mouse drag
                    if (window.get_tile_match () != null && !window.maximized_horizontally) {
                        var old_end = old_rect_size_change.x + old_rect_size_change.width;
                        var new_end = new_rect.x + new_rect.width;

                        // a tiled window is just resized (and not moved) if its start_x or its end_x stays the same
                        if (old_rect_size_change.x == new_rect.x || old_end == new_end) {
                            break;
                        }
                    }
                    maximize (actor, new_rect.x, new_rect.y, new_rect.width, new_rect.height);
                    break;
                case Meta.SizeChange.UNMAXIMIZE:
                    unmaximize (actor, new_rect.x, new_rect.y, new_rect.width, new_rect.height);
                    break;
                case Meta.SizeChange.FULLSCREEN:
                case Meta.SizeChange.UNFULLSCREEN:
                    handle_fullscreen_window (window, which_change_local);
                    break;
            }

            size_change_completed (actor);
        }

        public override void minimize (Meta.WindowActor actor) {
            const int duration = AnimationDuration.MINIMIZE;

            if (!enable_animations
                || duration == 0
                || actor.get_meta_window ().window_type != Meta.WindowType.NORMAL) {
                minimize_completed (actor);
                return;
            }

            kill_window_effects (actor);
            minimizing.add (actor);

            int width, height;
#if HAS_MUTTER330
            get_display ().get_size (out width, out height);
#else
            get_screen ().get_size (out width, out height);
#endif

            Meta.Rectangle icon = {};
            if (actor.get_meta_window ().get_icon_geometry (out icon)) {
                // Fix icon position and size according to ui scaling factor.
                int ui_scale = InternalUtils.get_ui_scaling_factor ();
                icon.x *= ui_scale;
                icon.y *= ui_scale;
                icon.width *= ui_scale;
                icon.height *= ui_scale;

                float scale_x = (float)icon.width / actor.width;
                float scale_y = (float)icon.height / actor.height;
                float anchor_x = (float)(actor.x - icon.x) / (icon.width - actor.width);
                float anchor_y = (float)(actor.y - icon.y) / (icon.height - actor.height);
                actor.set_pivot_point (anchor_x, anchor_y);

                actor.save_easing_state ();
                actor.set_easing_mode (Clutter.AnimationMode.EASE_IN_EXPO);
                actor.set_easing_duration (duration);
                actor.set_scale (scale_x, scale_y);
                actor.opacity = 0U;
                actor.restore_easing_state ();

                ulong minimize_handler_id = 0UL;
                minimize_handler_id = actor.transitions_completed.connect (() => {
                    actor.disconnect (minimize_handler_id);
                    actor.set_pivot_point (0.0f, 0.0f);
                    actor.set_scale (1.0f, 1.0f);
                    actor.opacity = 255U;
                    minimize_completed (actor);
                    minimizing.remove (actor);
                });

            } else {
                actor.set_pivot_point (0.5f, 1.0f);

                actor.save_easing_state ();
                actor.set_easing_mode (Clutter.AnimationMode.EASE_IN_EXPO);
                actor.set_easing_duration (duration);
                actor.set_scale (0.0f, 0.0f);
                actor.opacity = 0U;
                actor.restore_easing_state ();

                ulong minimize_handler_id = 0UL;
                minimize_handler_id = actor.transitions_completed.connect (() => {
                    actor.disconnect (minimize_handler_id);
                    actor.set_pivot_point (0.0f, 0.0f);
                    actor.set_scale (1.0f, 1.0f);
                    actor.opacity = 255U;
                    minimize_completed (actor);
                    minimizing.remove (actor);
                });
            }
        }

        void maximize (Meta.WindowActor actor, int ex, int ey, int ew, int eh) {
            const int duration = AnimationDuration.SNAP;

            if (!enable_animations
                || duration == 0) {
                return;
            }

            kill_window_effects (actor);

            var window = actor.get_meta_window ();
            if (window.maximized_horizontally && behavior_settings.get_boolean ("move-maximized-workspace")) {
                move_window_to_next_ws (window);
            }

            if (window.window_type == Meta.WindowType.NORMAL) {
                Meta.Rectangle fallback = { (int) actor.x, (int) actor.y, (int) actor.width, (int) actor.height };
                var window_geometry = WindowListener.get_default ().get_unmaximized_state_geometry (window);
                var old_inner_rect = window_geometry != null ? window_geometry.inner : fallback;
                var old_outer_rect = window_geometry != null ? window_geometry.outer : fallback;

                var old_actor = Utils.get_window_actor_snapshot (actor, old_inner_rect, old_outer_rect);
                if (old_actor == null) {
                    return;
                }

                maximizing.add (actor);
                old_actor.set_position (old_inner_rect.x, old_inner_rect.y);

                ui_group.add_child (old_actor);

                // FIMXE that's a hacky part. There is a short moment right after maximized_completed
                //       where the texture is screwed up and shows things it's not supposed to show,
                //       resulting in flashing. Waiting here transparently shortly fixes that issue. There
                //       appears to be no signal that would inform when that moment happens.
                //       We can't spend arbitrary amounts of time transparent since the overlay fades away,
                //       about a third has proven to be a solid time. So this fix will only apply for
                //       durations >= FLASH_PREVENT_TIMEOUT*3
                const int FLASH_PREVENT_TIMEOUT = 80;
                var delay = 0;
                if (FLASH_PREVENT_TIMEOUT <= duration / 3) {
                    actor.opacity = 0;
                    delay = FLASH_PREVENT_TIMEOUT;
                    Timeout.add (FLASH_PREVENT_TIMEOUT, () => {
                        actor.opacity = 255;
                        return false;
                    });
                }

                var scale_x = (double) ew / old_inner_rect.width;
                var scale_y = (double) eh / old_inner_rect.height;

                old_actor.save_easing_state ();
                old_actor.set_easing_mode (Clutter.AnimationMode.EASE_IN_OUT_QUAD);
                old_actor.set_easing_duration (duration);
                old_actor.set_position (ex, ey);
                old_actor.set_scale (scale_x, scale_y);

                // the opacity animation is special, since we have to wait for the
                // FLASH_PREVENT_TIMEOUT to be done before we can safely fade away
                old_actor.save_easing_state ();
                old_actor.set_easing_delay (delay);
                old_actor.set_easing_duration (duration - delay);
                old_actor.opacity = 0;
                old_actor.restore_easing_state ();

                ulong maximize_old_handler_id = 0UL;
                maximize_old_handler_id = old_actor.transitions_completed.connect (() => {
                    old_actor.disconnect (maximize_old_handler_id);
                    old_actor.destroy ();
                    actor.set_translation (0.0f, 0.0f, 0.0f);
                });

                old_actor.restore_easing_state ();

                actor.set_pivot_point (0.0f, 0.0f);
                actor.set_translation (old_inner_rect.x - ex, old_inner_rect.y - ey, 0.0f);
                actor.set_scale (1.0f / scale_x, 1.0f / scale_y);

                actor.save_easing_state ();
                actor.set_easing_mode (Clutter.AnimationMode.EASE_IN_OUT_QUAD);
                actor.set_easing_duration (duration);
                actor.set_scale (1.0f, 1.0f);
                actor.set_translation (0.0f, 0.0f, 0.0f);
                actor.restore_easing_state ();

                ulong handler_id = 0UL;
                handler_id = actor.transitions_completed.connect (() => {
                    actor.disconnect (handler_id);
                    maximizing.remove (actor);
                });
            }
        }

        public override void unminimize (Meta.WindowActor actor) {
            if (!enable_animations) {
                actor.show ();
                unminimize_completed (actor);
                return;
            }

            var window = actor.get_meta_window ();

            actor.remove_all_transitions ();
            actor.show ();

            switch (window.window_type) {
                case Meta.WindowType.NORMAL:
                    var duration = AnimationDuration.MINIMIZE;
                    if (duration == 0) {
                        unminimize_completed (actor);
                        return;
                    }

                    unminimizing.add (actor);

                    actor.set_pivot_point (0.5f, 1.0f);
                    actor.set_scale (0.01f, 0.1f);
                    actor.opacity = 0U;

                    actor.save_easing_state ();
                    actor.set_easing_mode (Clutter.AnimationMode.EASE_OUT_EXPO);
                    actor.set_easing_duration (duration);
                    actor.set_scale (1.0f, 1.0f);
                    actor.opacity = 255U;
                    actor.restore_easing_state ();

                    ulong unminimize_handler_id = 0UL;
                    unminimize_handler_id = actor.transitions_completed.connect (() => {
                        actor.disconnect (unminimize_handler_id);
                        unminimizing.remove (actor);
                        unminimize_completed (actor);
                    });

                    break;
                default:
                    unminimize_completed (actor);
                    break;
            }
        }

        public override void map (Meta.WindowActor actor) {
            var window = actor.get_meta_window ();
            if (!enable_animations) {
                actor.show ();
                map_completed (actor);

                if (InternalUtils.get_window_is_normal (window) && window.get_layer () == Meta.StackLayer.BOTTOM) {
                    show_bottom_stack_window (window);
                }

                return;
            }

            actor.remove_all_transitions ();
            actor.show ();

            switch (window.window_type) {
                case Meta.WindowType.NORMAL:
                    var duration = AnimationDuration.MINIMIZE;
                    if (duration == 0) {
                        map_completed (actor);
                        return;
                    }

                    mapping.add (actor);

                    if (window.maximized_vertically || window.maximized_horizontally) {
                        var outer_rect = window.get_frame_rect ();
                        actor.set_position (outer_rect.x, outer_rect.y);
                    }

                    actor.set_pivot_point (0.5f, 1.0f);
                    actor.set_scale (0.01f, 0.1f);
                    actor.opacity = 0;

                    actor.save_easing_state ();
                    actor.set_easing_mode (Clutter.AnimationMode.EASE_OUT_EXPO);
                    actor.set_easing_duration (duration);
                    actor.set_scale (1.0f, 1.0f);
                    actor.opacity = 255U;
                    actor.restore_easing_state ();

                    ulong map_handler_id = 0UL;
                    map_handler_id = actor.transitions_completed.connect (() => {
                        actor.disconnect (map_handler_id);
                        mapping.remove (actor);
                        map_completed (actor);

                        if (window.get_layer () == Meta.StackLayer.BOTTOM) {
                            show_bottom_stack_window (window);
                        }
                    });
                    break;
                case Meta.WindowType.MENU:
                case Meta.WindowType.DROPDOWN_MENU:
                case Meta.WindowType.POPUP_MENU:
                    var duration = AnimationDuration.MENU_MAP;
                    if (duration == 0) {
                        map_completed (actor);
                        return;
                    }

                    mapping.add (actor);

                    actor.set_pivot_point (0.5f, 0.5f);
                    actor.set_pivot_point_z (0.2f);
                    actor.set_scale (0.9f, 0.9f);
                    actor.opacity = 0;

                    actor.save_easing_state ();
                    actor.set_easing_mode (Clutter.AnimationMode.EASE_OUT_QUAD);
                    actor.set_easing_duration (duration);
                    actor.set_scale (1.0f, 1.0f);
                    actor.opacity = 255U;
                    actor.restore_easing_state ();

                    ulong map_handler_id = 0UL;
                    map_handler_id = actor.transitions_completed.connect (() => {
                        actor.disconnect (map_handler_id);
                        mapping.remove (actor);
                        map_completed (actor);
                    });
                    break;
                case Meta.WindowType.MODAL_DIALOG:
                case Meta.WindowType.DIALOG:

                    mapping.add (actor);

                    actor.set_pivot_point (0.5f, 0.5f);
                    actor.set_scale (0.9f, 0.9f);
                    actor.opacity = 0;

                    actor.save_easing_state ();
                    actor.set_easing_mode (Clutter.AnimationMode.EASE_OUT_QUAD);
                    actor.set_easing_duration (150);
                    actor.set_scale (1.0f, 1.0f);
                    actor.opacity = 255U;
                    actor.restore_easing_state ();

                    ulong map_handler_id = 0UL;
                    map_handler_id = actor.transitions_completed.connect (() => {
                        actor.disconnect (map_handler_id);
                        mapping.remove (actor);
                        map_completed (actor);

                        if (window.get_layer () == Meta.StackLayer.BOTTOM) {
                            show_bottom_stack_window (window);
                        }
                    });

                    var appearance_settings = new GLib.Settings (Config.SCHEMA + ".appearance");
                    if (appearance_settings.get_boolean ("dim-parents") &&
                        window.window_type == Meta.WindowType.MODAL_DIALOG &&
                        window.is_attached_dialog ())
                        dim_window (window.find_root_ancestor (), true);

                    break;
                case Meta.WindowType.NOTIFICATION:
                    notification_stack.show_notification (actor);
                    map_completed (actor);

                    break;
                default:
                    map_completed (actor);
                    break;
            }
        }

        public override void destroy (Meta.WindowActor actor) {
            var window = actor.get_meta_window ();

            ws_assoc.remove (window);

            if (!enable_animations) {
                destroy_completed (actor);

                // only NORMAL windows have icons
                if (window.window_type == Meta.WindowType.NORMAL)
                    Utils.request_clean_icon_cache (get_all_xids ());

                return;
            }

            actor.remove_all_transitions ();

            switch (window.window_type) {
                case Meta.WindowType.NORMAL:
                    const int duration = AnimationDuration.CLOSE;
                    if (duration == 0) {
                        destroy_completed (actor);
                        return;
                    }

                    destroying.add (actor);

                    actor.set_pivot_point (0.5f, 0.5f);
                    actor.show ();

                    actor.save_easing_state ();
                    actor.set_easing_mode (Clutter.AnimationMode.LINEAR);
                    actor.set_easing_duration (duration);
                    actor.set_scale (0.8f, 0.8f);
                    actor.opacity = 0U;
                    actor.restore_easing_state ();

                    ulong destroy_handler_id = 0UL;
                    destroy_handler_id = actor.transitions_completed.connect (() => {
                        actor.disconnect (destroy_handler_id);
                        destroying.remove (actor);
                        destroy_completed (actor);
                        Utils.request_clean_icon_cache (get_all_xids ());
                    });
                    break;
                case Meta.WindowType.MODAL_DIALOG:
                case Meta.WindowType.DIALOG:
                    destroying.add (actor);

                    actor.set_pivot_point (0.5f, 0.5f);
                    actor.save_easing_state ();
                    actor.set_easing_mode (Clutter.AnimationMode.EASE_OUT_QUAD);
                    actor.set_easing_duration (100);
                    actor.set_scale (0.9f, 0.9f);
                    actor.opacity = 0U;
                    actor.restore_easing_state ();

                    ulong destroy_handler_id = 0UL;
                    destroy_handler_id = actor.transitions_completed.connect (() => {
                        actor.disconnect (destroy_handler_id);
                        destroying.remove (actor);
                        destroy_completed (actor);
                    });

                    dim_window (window.find_root_ancestor (), false);

                    break;
                case Meta.WindowType.MENU:
                case Meta.WindowType.DROPDOWN_MENU:
                case Meta.WindowType.POPUP_MENU:
                    var duration = AnimationDuration.MENU_MAP;
                    if (duration == 0) {
                        destroy_completed (actor);
                        return;
                    }

                    destroying.add (actor);
                    actor.save_easing_state ();
                    actor.set_easing_mode (Clutter.AnimationMode.EASE_OUT_QUAD);
                    actor.set_easing_duration (duration);
                    actor.set_scale (0.8f, 0.8f);
                    actor.opacity = 0U;
                    actor.restore_easing_state ();

                    ulong destroy_handler_id = 0UL;
                    destroy_handler_id = actor.transitions_completed.connect (() => {
                        actor.disconnect (destroy_handler_id);
                        destroying.remove (actor);
                        destroy_completed (actor);
                    });
                    break;
                case Meta.WindowType.NOTIFICATION:
                    destroying.add (actor);
                    notification_stack.destroy_notification (actor);

                    ulong destroy_handler_id = 0UL;
                    destroy_handler_id = actor.transitions_completed.connect (() => {
                        actor.disconnect (destroy_handler_id);
                        destroying.remove (actor);
                        destroy_completed (actor);
                    });
                    break;
                default:
                    destroy_completed (actor);
                    break;
            }
        }

        void unmaximize (Meta.WindowActor actor, int ex, int ey, int ew, int eh) {
            const int duration = AnimationDuration.SNAP;
            if (!enable_animations
                || duration == 0) {
                return;
            }

            kill_window_effects (actor);
            var window = actor.get_meta_window ();

            if (behavior_settings.get_boolean ("move-maximized-workspace")) {
                move_window_to_old_ws (window);
            }

            if (window.window_type == Meta.WindowType.NORMAL) {
                float offset_x, offset_y, offset_width, offset_height;
                var unmaximized_window_geometry = WindowListener.get_default ().get_unmaximized_state_geometry (window);

                if (unmaximized_window_geometry != null) {
                    offset_x = unmaximized_window_geometry.outer.x - unmaximized_window_geometry.inner.x;
                    offset_y = unmaximized_window_geometry.outer.y - unmaximized_window_geometry.inner.y;
                    offset_width = unmaximized_window_geometry.outer.width - unmaximized_window_geometry.inner.width;
                    offset_height = unmaximized_window_geometry.outer.height - unmaximized_window_geometry.inner.height;
                } else {
                    offset_x = 0;
                    offset_y = 0;
                    offset_width = 0;
                    offset_height = 0;
                }

                Meta.Rectangle old_rect = { (int) actor.x, (int) actor.y, (int) actor.width, (int) actor.height };
                var old_actor = Utils.get_window_actor_snapshot (actor, old_rect, old_rect);

                if (old_actor == null) {
                    return;
                }

                unmaximizing.add (actor);

                old_actor.set_position (old_rect.x, old_rect.y);

                ui_group.add_child (old_actor);

                var scale_x = (float) ew / old_rect.width;
                var scale_y = (float) eh / old_rect.height;

                old_actor.save_easing_state ();
                old_actor.set_easing_mode (Clutter.AnimationMode.EASE_IN_OUT_QUAD);
                old_actor.set_easing_duration (duration);
                old_actor.set_position (ex, ey);
                old_actor.set_scale (scale_x, scale_y);
                old_actor.opacity = 0U;
                old_actor.restore_easing_state ();

                ulong unmaximize_old_handler_id = 0UL;
                unmaximize_old_handler_id = old_actor.transitions_completed.connect (() => {
                    old_actor.disconnect (unmaximize_old_handler_id);
                    old_actor.destroy ();
                });

                var maximized_x = actor.x;
                var maximized_y = actor.y;
                actor.set_pivot_point (0.0f, 0.0f);
                actor.set_position (ex, ey);
                actor.set_translation (-ex + offset_x * (1.0f / scale_x - 1.0f) + maximized_x, -ey + offset_y * (1.0f / scale_y - 1.0f) + maximized_y, 0.0f);
                actor.set_scale (1.0f / scale_x, 1.0f / scale_y);

                actor.save_easing_state ();
                actor.set_easing_mode (Clutter.AnimationMode.EASE_IN_OUT_QUAD);
                actor.set_easing_duration (duration);
                actor.set_scale (1.0f, 1.0f);
                actor.set_translation (0.0f, 0.0f, 0.0f);
                actor.restore_easing_state ();

                ulong handler_id = 0UL;
                handler_id = actor.transitions_completed.connect (() => {
                    actor.disconnect (handler_id);
                    unmaximizing.remove (actor);
                });
            }
        }

        void move_window_to_next_ws (Meta.Window window) {
            unowned Meta.Workspace win_ws = window.get_workspace ();

            // Do nothing if the current workspace would be empty
            if (Utils.get_n_windows (win_ws) <= 1) {
                return;
            }

            var old_ws_index = win_ws.index ();
            var new_ws_index = old_ws_index + 1;
            InternalUtils.insert_workspace_with_window (new_ws_index, window);

#if HAS_MUTTER330
            unowned Meta.Display display = get_display ();
            var time = display.get_current_time ();
            var new_ws_obj = display.get_workspace_manager ().get_workspace_by_index (new_ws_index);
#else
            unowned Meta.Screen screen = get_screen ();
            var time = get_screen ().get_display ().get_current_time ();
            var new_ws_obj = screen.get_workspace_by_index (new_ws_index);
#endif
            window.change_workspace (new_ws_obj);
            new_ws_obj.activate_with_focus (window, time);

            ws_assoc.insert (window, old_ws_index);
        }

        private void move_window_to_old_ws (Meta.Window window) {
            unowned Meta.Workspace win_ws = window.get_workspace ();

            // Do nothing if the current workspace is populated with other windows
            if (Utils.get_n_windows (win_ws) > 1) {
                return;
            }

            if (!ws_assoc.contains (window)) {
                return;
            }

            var old_ws_index = ws_assoc.get (window);
            var new_ws_index = win_ws.index ();

#if HAS_MUTTER330
            unowned Meta.Display display = get_display ();
            unowned Meta.WorkspaceManager workspace_manager = display.get_workspace_manager ();
            if (new_ws_index != old_ws_index && old_ws_index < workspace_manager.get_n_workspaces ()) {
                uint time = display.get_current_time ();
                var old_ws_obj = workspace_manager.get_workspace_by_index (old_ws_index);
#else
            unowned Meta.Screen screen = get_screen ();
            if (new_ws_index != old_ws_index && old_ws_index < screen.get_n_workspaces ()) {
                uint time = screen.get_display ().get_current_time ();
                var old_ws_obj = screen.get_workspace_by_index (old_ws_index);
#endif
                window.change_workspace (old_ws_obj);
                old_ws_obj.activate_with_focus (window, time);
            }

            ws_assoc.remove (window);
        }

        // Cancel attached animation of an actor and reset it
        bool end_animation (ref Gee.HashSet<Meta.WindowActor> list, Meta.WindowActor actor) {
            if (!list.contains (actor))
                return false;

            if (actor.is_destroyed ()) {
                list.remove (actor);
                return false;
            }

            actor.remove_all_transitions ();
            actor.opacity = 255U;
            actor.set_scale (1.0f, 1.0f);
            actor.rotation_angle_x = 0.0f;
            actor.set_pivot_point (0.0f, 0.0f);

            list.remove (actor);
            return true;
        }

        public override void kill_window_effects (Meta.WindowActor actor) {
            if (end_animation (ref mapping, actor))
                map_completed (actor);
            if (end_animation (ref unminimizing, actor))
                unminimize_completed (actor);
            if (end_animation (ref minimizing, actor))
                minimize_completed (actor);
            if (end_animation (ref destroying, actor))
                destroy_completed (actor);

            end_animation (ref unmaximizing, actor);
            end_animation (ref maximizing, actor);
        }

        /*workspace switcher*/
        List<Clutter.Actor>? windows;
        List<Clutter.Actor>? parents;
        List<Clutter.Actor>? tmp_actors;

        public override void switch_workspace (int from, int to, Meta.MotionDirection direction) {
            const int animation_duration = AnimationDuration.WORKSPACE_SWITCH;

            if (!enable_animations
                || animation_duration == 0
                || (direction != Meta.MotionDirection.UP && direction != Meta.MotionDirection.DOWN)) {
                switch_workspace_completed ();
                return;
            }

            float screen_width, screen_height;
#if HAS_MUTTER330
            unowned Meta.Display display = get_display ();
            var primary = display.get_primary_monitor ();
            var move_primary_only = InternalUtils.workspaces_only_on_primary ();
            var monitor_geom = display.get_monitor_geometry (primary);
            var clone_offset_x = move_primary_only ? monitor_geom.x : 0.0f;
            var clone_offset_y = move_primary_only ? monitor_geom.y : 0.0f;

            display.get_size (out screen_width, out screen_height);

            unowned Meta.WorkspaceManager manager = display.get_workspace_manager ();
            unowned Meta.Workspace workspace_from = manager.get_workspace_by_index (from);
            unowned Meta.Workspace workspace_to = manager.get_workspace_by_index (to);
#else
            var screen = get_screen ();
            var primary = screen.get_primary_monitor ();
            var move_primary_only = InternalUtils.workspaces_only_on_primary ();
            var monitor_geom = screen.get_monitor_geometry (primary);
            var clone_offset_x = move_primary_only ? monitor_geom.x : 0.0f;
            var clone_offset_y = move_primary_only ? monitor_geom.y : 0.0f;

            screen.get_size (out screen_width, out screen_height);

            unowned Meta.Workspace workspace_from = screen.get_workspace_by_index (from);
            unowned Meta.Workspace workspace_to = screen.get_workspace_by_index (to);
#endif

            var main_container = new Clutter.Actor ();
            var static_windows = new Clutter.Actor ();
            var in_group = new Clutter.Actor ();
            var out_group = new Clutter.Actor ();
            windows = new List<Meta.WindowActor> ();
            parents = new List<Clutter.Actor> ();
            tmp_actors = new List<Clutter.Clone> ();

            tmp_actors.prepend (main_container);
            tmp_actors.prepend (in_group);
            tmp_actors.prepend (out_group);
            tmp_actors.prepend (static_windows);

            window_group.add_child (main_container);

            // prepare wallpaper
            Clutter.Actor wallpaper;
            if (move_primary_only) {
                wallpaper = background_group.get_child_at_index (primary);
                wallpaper.set_data<int> ("prev-x", (int) wallpaper.x);
                wallpaper.set_data<int> ("prev-y", (int) wallpaper.y);
            } else
                wallpaper = background_group;

            windows.prepend (wallpaper);
            parents.prepend (wallpaper.get_parent ());

            var wallpaper_clone = new Clutter.Clone (wallpaper);
            tmp_actors.prepend (wallpaper_clone);

            // pack all containers
            clutter_actor_reparent (wallpaper, main_container);
            main_container.add_child (wallpaper_clone);
            main_container.add_child (out_group);
            main_container.add_child (in_group);
            main_container.add_child (static_windows);

            // if we have a move action, pack that window to the static ones
            if (moving != null) {
                var moving_actor = (Meta.WindowActor) moving.get_compositor_private ();

                windows.prepend (moving_actor);
                parents.prepend (moving_actor.get_parent ());

                moving_actor.set_translation (-clone_offset_x, -clone_offset_y, 0);
                clutter_actor_reparent (moving_actor, static_windows);
            }

            var to_has_fullscreened = false;
            var from_has_fullscreened = false;
            var docks = new List<Meta.WindowActor> ();

            // collect all windows and put them in the appropriate containers
#if HAS_MUTTER330
            foreach (unowned Meta.WindowActor actor in display.get_window_actors ()) {
#else
            foreach (unowned Meta.WindowActor actor in screen.get_window_actors ()) {
#endif
                if (actor.is_destroyed ())
                    continue;

                unowned Meta.Window window = actor.get_meta_window ();

                if (!window.showing_on_its_workspace () ||
                    (move_primary_only && window.get_monitor () != primary) ||
                    (moving != null && window == moving))
                    continue;

                if (window.is_on_all_workspaces ()) {
                    // only collect docks here that need to be displayed on both workspaces
                    // all other windows will be collected below
                    if (window.window_type == Meta.WindowType.DOCK) {
                        docks.prepend (actor);
                    } else {
                        // windows that are on all workspaces will be faded out and back in
                        windows.prepend (actor);
                        parents.prepend (actor.get_parent ());

                        if (window.window_type == Meta.WindowType.NOTIFICATION) {
                            reparent_notification_window (actor, static_windows);
                        } else {
                            clutter_actor_reparent (actor, static_windows);
                            actor.set_translation (-clone_offset_x, -clone_offset_y, 0);
                            actor.save_easing_state ();
                            actor.set_easing_duration (300);
                            actor.opacity = 0;
                            actor.restore_easing_state ();
                        }
                    }

                    continue;
                }

                if (window.get_workspace () == workspace_from) {
                    windows.append (actor);
                    parents.append (actor.get_parent ());
                    actor.set_translation (-clone_offset_x, -clone_offset_y, 0);
                    clutter_actor_reparent (actor, out_group);

                    if (window.fullscreen)
                        from_has_fullscreened = true;

                } else if (window.get_workspace () == workspace_to) {
                    windows.append (actor);
                    parents.append (actor.get_parent ());
                    actor.set_translation (-clone_offset_x, -clone_offset_y, 0);
                    clutter_actor_reparent (actor, in_group);

                    if (window.fullscreen)
                        to_has_fullscreened = true;

                }
            }

            // make sure we don't add docks when there are fullscreened
            // windows on one of the groups. Simply raising seems not to
            // work, mutter probably reverts the order internally to match
            // the display stack
            foreach (var window in docks) {
                if (!to_has_fullscreened) {
                    var clone = new SafeWindowClone (window.get_meta_window ());
                    clone.x = window.x - clone_offset_x;
                    clone.y = window.y - clone_offset_y;

                    in_group.add_child (clone);
                    tmp_actors.prepend (clone);
                }

                if (!from_has_fullscreened) {
                    windows.prepend (window);
                    parents.prepend (window.get_parent ());
                    window.set_translation (-clone_offset_x, -clone_offset_y, 0.0f);

                    clutter_actor_reparent (window, out_group);
                }
            }

            main_container.clip_to_allocation = true;
            main_container.x = move_primary_only ? monitor_geom.x : 0.0f;
            main_container.y = move_primary_only ? monitor_geom.y : 0.0f;
            main_container.width = move_primary_only ? monitor_geom.width : screen_width;
            main_container.height = move_primary_only ? monitor_geom.height : screen_height;

            var x2 = move_primary_only ? monitor_geom.width : screen_width;
            if (direction == Meta.MotionDirection.DOWN)
                x2 = -x2;

            out_group.x = 0.0f;
            wallpaper.x = 0.0f;
            in_group.x = -x2;
            wallpaper_clone.x = -x2;

            // The wallpapers need to move upwards inside the container to match their
            // original position before/after the transition.
            if (move_primary_only) {
                wallpaper.y = -monitor_geom.y;
                wallpaper_clone.y = -monitor_geom.y;
            }

            in_group.clip_to_allocation = out_group.clip_to_allocation = true;
            in_group.width = out_group.width = move_primary_only ? monitor_geom.width : screen_width;
            in_group.height = out_group.height = move_primary_only ? monitor_geom.height : screen_height;

            var animation_mode = Clutter.AnimationMode.EASE_OUT_CUBIC;

            out_group.set_easing_mode (animation_mode);
            out_group.set_easing_duration (animation_duration);
            in_group.set_easing_mode (animation_mode);
            in_group.set_easing_duration (animation_duration);
            wallpaper_clone.set_easing_mode (animation_mode);
            wallpaper_clone.set_easing_duration (animation_duration);

            wallpaper.save_easing_state ();
            wallpaper.set_easing_mode (animation_mode);
            wallpaper.set_easing_duration (animation_duration);

            out_group.x = x2;
            in_group.x = 0.0f;

            wallpaper.x = x2;
            wallpaper_clone.x = 0.0f;
            wallpaper.restore_easing_state ();

            var transition = in_group.get_transition ("x");
            if (transition != null)
                transition.completed.connect (end_switch_workspace);
            else
                end_switch_workspace ();
        }

        void end_switch_workspace () {
            if (windows == null || parents == null)
                return;

#if HAS_MUTTER330
            unowned Meta.Display display = get_display ();
            var active_workspace = display.get_workspace_manager ().get_active_workspace ();
#else
            var screen = get_screen ();
            var active_workspace = screen.get_active_workspace ();
#endif

            for (var i = 0; i < windows.length (); i++) {
                var actor = windows.nth_data (i);
                actor.set_translation (0.0f, 0.0f, 0.0f);

                // to maintain the correct order of monitor, we need to insert the Background
                // back manually
                if (actor is BackgroundManager) {
                    var background = (BackgroundManager) actor;

                    background.get_parent ().remove_child (background);
                    background_group.insert_child_at_index (background, background.monitor_index);
                    background.x = background.steal_data<int> ("prev-x");
                    background.y = background.steal_data<int> ("prev-y");
                    continue;
                } else if (actor is Meta.BackgroundGroup) {
                    actor.x = 0;
                    // thankfully mutter will take care of stacking it at the right place for us
                    clutter_actor_reparent (actor, window_group);
                    continue;
                }

                unowned Meta.WindowActor? window = actor as Meta.WindowActor;
                if (window == null) {
                    clutter_actor_reparent (actor, parents.nth_data (i));
                    continue;
                }

                unowned Meta.Window? meta_window = window.get_meta_window ();
                if (!window.is_destroyed ()) {
                    if (meta_window != null
                        && meta_window.get_window_type () == Meta.WindowType.NOTIFICATION) {
                        reparent_notification_window (actor, parents.nth_data (i));
                    } else {
                        clutter_actor_reparent (actor, parents.nth_data (i));
                    }
                }

                kill_window_effects (window);

                if (meta_window != null
                    && meta_window.get_workspace () != active_workspace
                    && !meta_window.is_on_all_workspaces ())
                    window.hide ();

                // some static windows may have been faded out
                if (actor.opacity < 255U) {
                    actor.save_easing_state ();
                    actor.set_easing_duration (300);
                    actor.opacity = 255U;
                    actor.restore_easing_state ();
                }
            }

            if (tmp_actors != null) {
                foreach (var actor in tmp_actors) {
                    actor.destroy ();
                }
                tmp_actors = null;
            }

            windows = null;
            parents = null;
            moving = null;

            switch_workspace_completed ();
        }

        public override void kill_switch_workspace () {
            end_switch_workspace ();
        }

        public override bool keybinding_filter (Meta.KeyBinding binding) {
            if (!is_modal ())
                return false;

            var modal_proxy = modal_stack.peek_head ();

            return (modal_proxy != null
                && modal_proxy.keybinding_filter != null
                && modal_proxy.keybinding_filter (binding));
        }

        public override void confirm_display_change () {
            var pid = Meta.Util.show_dialog ("--question",
                _("Does the display look OK?"),
                "30",
                null,
                _("Keep This Configuration"),
                _("Restore Previous Configuration"),
                "preferences-desktop-display",
                0,
                null, null);

            ChildWatch.add (pid, (pid, status) => {
                var ok = false;
                try {
                    ok = Process.check_exit_status (status);
                } catch (Error e) {}

                complete_display_change (ok);
            });
        }

        public override unowned Meta.PluginInfo? plugin_info () {
            return info;
        }

        /**
         * Notification windows are a special case where the transition state needs
         * to be preserved when reparenting the actor. Because Clutter doesn't allow specifying
         * remove_child flags we will save the elapsed time of required transitions and
         * then advance back to it when we're done reparenting.
         */
        static void reparent_notification_window (Clutter.Actor actor, Clutter.Actor new_parent) {
            unowned Clutter.Transition? entry_transition = actor.get_transition (NotificationStack.TRANSITION_ENTRY_NAME);
            unowned Clutter.Transition? position_transition = actor.get_data<Clutter.Transition?> (NotificationStack.TRANSITION_MOVE_STACK_ID);

            uint elapsed_entry = 0U, elapsed_position = 0U;

            bool save_entry = entry_transition != null && entry_transition.is_playing ();
            if (save_entry) {
                elapsed_entry = entry_transition.get_elapsed_time ();
            }

            bool save_position = position_transition != null && position_transition.is_playing ();
            if (save_position) {
                elapsed_position = position_transition.get_elapsed_time ();
            }

            clutter_actor_reparent (actor, new_parent);

            if (save_entry) {
                entry_transition.advance (elapsed_entry);
                entry_transition.start ();
            }

            if (save_position) {
                position_transition.advance (elapsed_position);
                position_transition.start ();
            }
        }

        static void clutter_actor_reparent (Clutter.Actor actor, Clutter.Actor new_parent) {
            if (actor == new_parent)
                return;

            actor.ref ();
            actor.get_parent ().remove_child (actor);
            new_parent.add_child (actor);
            actor.unref ();
        }
    }

    [CCode (cname="clutter_x11_get_stage_window")]
    public extern X.Window x_get_stage_window (Clutter.Actor stage);
}
