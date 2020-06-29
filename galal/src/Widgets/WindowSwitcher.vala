//
//  Copyright (C) 2012 Tom Beckmann, Rico Tzschichholz
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

using Clutter;
using Meta;

namespace Gala {
    public class WindowSwitcher : Clutter.Actor {
        const int MIN_DELTA = 100;
        const float BACKGROUND_OPACITY = 155.0f;
        const float DIM_WINDOW_BRIGHTNESS = -BACKGROUND_OPACITY / 255.0f;

        public WindowManager wm { get; construct; }

        WindowIcon? current_window = null;

        Actor window_clones;
        List<unowned Actor> clone_sort_order;

        WindowActor? dock_window;
        Actor dock;
        Plank.Surface? dock_surface;
        Plank.DockTheme dock_theme;
        Plank.DockPreferences dock_settings;
        float dock_y_offset;
        float dock_height_offset;
        int ui_scale_factor = 1;
        FileMonitor monitor;

        Actor background;

        uint modifier_mask;
        int64 last_switch = 0;
        bool closing = false;
        ModalProxy modal_proxy;

        // estimated value, if possible
        float dock_width = 0.0f;
        int n_dock_items = 0;

        public WindowSwitcher (WindowManager wm) {
            Object (wm: wm);
        }

        construct {
            // pull drawing methods from libplank
            dock_settings = new Plank.DockPreferences ("dock1");
            dock_settings.notify.connect (update_dock);
            dock_settings.notify["Theme"].connect (load_dock_theme);

            var launcher_folder = Plank.Paths.AppConfigFolder.get_child ("dock1").get_child ("launchers");

            if (launcher_folder.query_exists ()) {
                try {
                    monitor = launcher_folder.monitor (FileMonitorFlags.NONE);
                    monitor.changed.connect (update_n_dock_items);
                } catch (Error e) { warning (e.message); }

                // initial update, pretend a file was created
                update_n_dock_items (launcher_folder, null, FileMonitorEvent.CREATED);
            }

            ui_scale_factor = InternalUtils.get_ui_scaling_factor ();

            dock = new Actor ();
            dock.layout_manager = new BoxLayout ();

            var dock_canvas = new Canvas ();
            dock_canvas.draw.connect (draw_dock_background);

            dock.content = dock_canvas;
            dock.actor_removed.connect (icon_removed);
            dock.notify["allocation"].connect (() =>
                dock_canvas.set_size ((int) dock.width, (int) dock.height));

            load_dock_theme ();

            window_clones = new Actor ();
            window_clones.actor_removed.connect (window_removed);

            background = new Actor ();
            background.background_color = Color.get_static (StaticColor.BLACK);
            update_background ();

            add_child (background);
            add_child (window_clones);
            add_child (dock);

#if HAS_MUTTER330
            Meta.MonitorManager.@get ().monitors_changed.connect (update_actors);
#else
            wm.get_screen ().monitors_changed.connect (update_actors);
#endif

            visible = false;
        }

        ~WindowSwitcher () {
            if (monitor != null)
                monitor.cancel ();


#if HAS_MUTTER330
            Meta.MonitorManager.@get ().monitors_changed.disconnect (update_actors);
#else
            wm.get_screen ().monitors_changed.disconnect (update_actors);
#endif
        }

        void load_dock_theme () {
            if (dock_theme != null)
                dock_theme.notify.disconnect (update_dock);

            dock_theme = new Plank.DockTheme (dock_settings.Theme);
            dock_theme.load ("dock");
            dock_theme.notify.connect (update_dock);

            update_dock ();
        }

        /**
         * set the values which don't get set every time and need to be updated when the theme changes
         */
        void update_dock () {
            ui_scale_factor = InternalUtils.get_ui_scaling_factor ();

#if HAS_MUTTER330
            unowned Meta.Display display = wm.get_display ();
            var geometry = display.get_monitor_geometry (display.get_primary_monitor ());
#else
            var screen = wm.get_screen ();
            var geometry = screen.get_monitor_geometry (screen.get_primary_monitor ());
#endif
            var layout = (BoxLayout) dock.layout_manager;

            var position = dock_settings.Position;
            var icon_size = dock_settings.IconSize * ui_scale_factor;
            var scaled_icon_size = icon_size / 10.0f;
            var horizontal = dock_settings.is_horizontal_dock ();

            var top_padding = (float) dock_theme.TopPadding * scaled_icon_size;
            var bottom_padding = (float) dock_theme.BottomPadding * scaled_icon_size;
            var item_padding = (float) dock_theme.ItemPadding * scaled_icon_size;
            var line_width = dock_theme.LineWidth * ui_scale_factor;

            var top_offset = 2 * line_width + top_padding;
            var bottom_offset = (dock_theme.BottomRoundness > 0 ? 2 * line_width : 0) + bottom_padding;

            layout.spacing = (uint) item_padding;
            layout.orientation = horizontal ? Orientation.HORIZONTAL : Orientation.VERTICAL;

            dock_y_offset = -top_offset;
            dock_height_offset = top_offset + bottom_offset;

            var height = icon_size + (top_offset > 0 ? top_offset : 0) + bottom_offset;

            if (horizontal) {
                dock.height = height;
                dock.x = Math.ceilf (geometry.x + geometry.width / 2.0f);
            } else {
                dock.width = height;
                dock.y = Math.ceilf (geometry.y + geometry.height / 2.0f);
            }

            switch (position) {
                case Gtk.PositionType.TOP:
                    dock.y = Math.ceilf (geometry.y);
                    break;
                case Gtk.PositionType.BOTTOM:
                    dock.y = Math.ceilf (geometry.y + geometry.height - height);
                    break;
                case Gtk.PositionType.LEFT:
                    dock.x = Math.ceilf (geometry.x);
                    break;
                case Gtk.PositionType.RIGHT:
                    dock.x = Math.ceilf (geometry.x + geometry.width - height);
                    break;
            }

            dock_surface = null;
        }

        void update_background () {
            int width = 0, height = 0;
#if HAS_MUTTER330
            wm.get_display ().get_size (out width, out height);
#else
            wm.get_screen ().get_size (out width, out height);
#endif

            background.set_size (width, height);
        }

        void update_actors () {
            update_dock ();
            update_background ();
        }

        bool draw_dock_background (Cairo.Context cr) {
            cr.set_operator (Cairo.Operator.CLEAR);
            cr.paint ();
            cr.set_operator (Cairo.Operator.OVER);

            var position = dock_settings.Position;

            var width = (int) dock.width;
            var height = (int) dock.height;

            switch (position) {
                case Gtk.PositionType.RIGHT:
                    width += (int) dock_height_offset;
                    break;
                case Gtk.PositionType.LEFT:
                    width -= (int) dock_y_offset;
                    break;
                case Gtk.PositionType.TOP:
                    height -= (int) dock_y_offset;
                    break;
                case Gtk.PositionType.BOTTOM:
                    height += (int) dock_height_offset;
                    break;
            }

            if (dock_surface == null || dock_surface.Width != width || dock_surface.Height != height) {
                var dummy_surface = new Plank.Surface.with_cairo_surface (1, 1, cr.get_target ());

                dock_surface = dock_theme.create_background (width / ui_scale_factor, height / ui_scale_factor, position, dummy_surface);
            }

            float x = 0, y = 0;
            switch (position) {
                case Gtk.PositionType.RIGHT:
                    x = dock_y_offset;
                    break;
                case Gtk.PositionType.BOTTOM:
                    y = dock_y_offset / ui_scale_factor;
                    break;
                case Gtk.PositionType.LEFT:
                    x = 0;
                    break;
                case Gtk.PositionType.TOP:
                    y = 0;
                    break;
            }

            cr.save ();
            cr.scale (ui_scale_factor, ui_scale_factor);
            cr.set_source_surface (dock_surface.Internal, x, y);
            cr.paint ();
            cr.restore ();

            return false;
        }

        void place_dock () {
            ui_scale_factor = InternalUtils.get_ui_scaling_factor ();

            var icon_size = dock_settings.IconSize * ui_scale_factor;
            var scaled_icon_size = icon_size / 10.0f;
            var line_width = dock_theme.LineWidth * ui_scale_factor;
            var horiz_padding = dock_theme.HorizPadding * scaled_icon_size;
            var item_padding = (float) dock_theme.ItemPadding * scaled_icon_size;
            var items_offset = (int) (2 * line_width + (horiz_padding > 0 ? horiz_padding : 0) + item_padding / 2);

            if (n_dock_items > 0)
                dock_width = n_dock_items * (item_padding + icon_size) + items_offset * 2;
            else
                dock_width = (dock_window != null ? dock_window.width : 300.0f);

            if (dock_settings.is_horizontal_dock ()) {
                dock.width = dock_width;
                dock.translation_x = Math.ceilf (-dock_width / 2.0f);
                dock.get_first_child ().margin_left = items_offset;
                dock.get_last_child ().margin_right = items_offset;
            } else {
                dock.height = dock_width;
                dock.translation_y = Math.ceilf (-dock_width / 2.0f);
                dock.get_first_child ().margin_top = items_offset;
                dock.get_last_child ().margin_bottom = items_offset;
            }

            dock.opacity = 255;
        }

        void animate_dock_width () {
            dock.save_easing_state ();
            dock.set_easing_duration (250);
            dock.set_easing_mode (AnimationMode.EASE_OUT_CUBIC);

            float dest_width;
            if (dock_settings.is_horizontal_dock ()) {
                dock.layout_manager.get_preferred_width (dock, dock.height, null, out dest_width);
                dock.width = dest_width;
                dock.translation_x = Math.ceilf (-dest_width / 2.0f);
            } else {
                dock.layout_manager.get_preferred_height (dock, dock.width, null, out dest_width);
                dock.height = dest_width;
                dock.translation_y = Math.ceilf (-dest_width / 2.0f);
            }

            dock.restore_easing_state ();
        }

        void show_background () {
            background.save_easing_state ();
            background.set_easing_duration (250);
            background.set_easing_mode (AnimationMode.EASE_OUT_CUBIC);
            background.opacity = (uint)BACKGROUND_OPACITY;
            background.restore_easing_state ();
        }

        void hide_background () {
            background.save_easing_state ();
            background.set_easing_duration (250);
            background.set_easing_mode (AnimationMode.EASE_OUT_CUBIC);
            background.opacity = 0;
            background.restore_easing_state ();
        }

        bool clicked_icon (Clutter.ButtonEvent event) {
            unowned WindowIcon icon = (WindowIcon) event.source;

            if (current_window != icon) {
                current_window = icon;
                dim_windows ();

                // wait for the dimming to finish
                Timeout.add (250, () => {
#if HAS_MUTTER330
                    close (wm.get_display ().get_current_time ());
#else
                    close (wm.get_screen ().get_display ().get_current_time ());
#endif
                    return false;
                });
            } else
                close (event.time);

            return true;
        }

        void window_removed (Actor actor) {
            clone_sort_order.remove (actor);
        }

        void icon_removed (Actor actor) {
            if (dock.get_n_children () == 1) {
#if HAS_MUTTER330
                close (wm.get_display ().get_current_time ());
#else
                close (wm.get_screen ().get_display ().get_current_time ());
#endif
                return;
            }

            if (actor == current_window) {
                current_window = (WindowIcon) current_window.get_next_sibling ();
                if (current_window == null)
                    current_window = (WindowIcon) dock.get_first_child ();

                dim_windows ();
            }

            animate_dock_width ();
        }

        public override bool key_release_event (Clutter.KeyEvent event) {
            if ((get_current_modifiers () & modifier_mask) == 0)
                close (event.time);

            return true;
        }

        public override void key_focus_out () {
#if HAS_MUTTER330
            close (wm.get_display ().get_current_time ());
#else
            close (wm.get_screen ().get_display ().get_current_time ());
#endif
        }

        [CCode (instance_pos = -1)]
#if HAS_MUTTER330
        public void handle_switch_windows (Display display, Window? window, Clutter.KeyEvent event,
            KeyBinding binding) {
#else
        public void handle_switch_windows (Display display, Screen screen, Window? window,
            Clutter.KeyEvent event, KeyBinding binding) {
#endif
            var now = get_monotonic_time () / 1000;
            if (now - last_switch < MIN_DELTA)
                return;

            // if we were still closing while the next invocation comes in, we need to cleanup
            // things right away
            if (visible && closing) {
                close_cleanup ();
            }

            last_switch = now;

#if HAS_MUTTER330
            var workspace = display.get_workspace_manager ().get_active_workspace ();
#else
            var workspace = screen.get_active_workspace ();
#endif
            var binding_name = binding.get_name ();
            var backward = binding_name.has_suffix ("-backward");

            // FIXME for unknown reasons, switch-applications-backward won't be emitted, so we
            //       test manually if shift is held down
            if (binding_name == "switch-applications")
                backward = ((get_current_modifiers () & ModifierType.SHIFT_MASK) != 0);

            if (visible && !closing) {
                current_window = next_window (workspace, backward);
                dim_windows ();
                return;
            }

            if (!collect_windows (workspace))
                return;

            set_primary_modifier (binding.get_mask ());

            current_window = next_window (workspace, backward);

            place_dock ();

            visible = true;
            closing = false;
            modal_proxy = wm.push_modal ();
            modal_proxy.keybinding_filter = (binding) => {
                // if it's not built-in, we can block it right away
                if (!binding.is_builtin ())
                    return true;

                // otherwise we determine by name if it's meant for us
                var name = binding.get_name ();

                return !(name == "switch-applications" || name == "switch-applications-backward"
                    || name == "switch-windows" || name == "switch-windows-backward");
            };

            animate_dock_width ();
            show_background ();

            dim_windows ();
            grab_key_focus ();

#if HAS_MUTTER330
            if ((get_current_modifiers () & modifier_mask) == 0)
                close (wm.get_display ().get_current_time ());
#else
            if ((get_current_modifiers () & modifier_mask) == 0)
                close (wm.get_screen ().get_display ().get_current_time ());
#endif
        }

        void close_cleanup () {
#if HAS_MUTTER330
            var display = wm.get_display ();
            var workspace = display.get_workspace_manager ().get_active_workspace ();
#else
            var screen = wm.get_screen ();
            var workspace = screen.get_active_workspace ();
#endif

            dock.destroy_all_children ();

            dock_window = null;
            visible = false;
            closing = false;

            window_clones.destroy_all_children ();

            // need to go through all the windows because of hidden dialogs
#if HAS_MUTTER330
            unowned GLib.List<Meta.WindowActor> window_actors = display.get_window_actors ();
#else
            unowned GLib.List<Meta.WindowActor> window_actors = screen.get_window_actors ();
#endif
            foreach (unowned Meta.WindowActor actor in window_actors) {
                if (actor.is_destroyed ())
                    continue;

                unowned Meta.Window window = actor.get_meta_window ();
                if (window.get_workspace () == workspace
                    && window.showing_on_its_workspace ())
                    actor.show ();
            }
        }

        void close (uint time) {
            if (closing)
                return;

            closing = true;
            last_switch = 0;

            foreach (var actor in clone_sort_order) {
                unowned SafeWindowClone clone = (SafeWindowClone) actor;

                // current window stays on top
                if (clone.window == current_window.window)
                    continue;

                clone.remove_effect_by_name ("brightness");

                // reset order
                window_clones.set_child_below_sibling (clone, null);

                if (!clone.window.minimized) {
                    clone.save_easing_state ();
                    clone.set_easing_duration (150);
                    clone.set_easing_mode (AnimationMode.EASE_OUT_CUBIC);
                    clone.z_position = 0;
                    clone.opacity = 255;
                    clone.restore_easing_state ();
                }
            }

            if (current_window != null) {
                current_window.window.activate (time);
                current_window = null;
            }

            wm.pop_modal (modal_proxy);

            if (dock_window != null)
                dock_window.opacity = 0;

            var dest_width = (dock_width > 0 ? dock_width : 600.0f);

            set_child_above_sibling (dock, null);

            if (dock_window != null) {
                dock_window.show ();
                dock_window.save_easing_state ();
                dock_window.set_easing_mode (AnimationMode.LINEAR);
                dock_window.set_easing_duration (250);
                dock_window.opacity = 255;
                dock_window.restore_easing_state ();
            }

            hide_background ();

            dock.save_easing_state ();
            dock.set_easing_duration (250);
            dock.set_easing_mode (AnimationMode.EASE_OUT_CUBIC);

            if (dock_settings.is_horizontal_dock ()) {
                dock.width = dest_width;
                dock.translation_x = Math.ceilf (-dest_width / 2.0f);
            } else {
                dock.height = dest_width;
                dock.translation_y = Math.ceilf (-dest_width / 2.0f);
            }

            dock.opacity = 0;
            dock.restore_easing_state ();

            var transition = dock.get_transition ("opacity");
            if (transition != null)
                transition.completed.connect (() => close_cleanup ());
            else
                close_cleanup ();
        }

        WindowIcon? add_window (Window window) {
            var actor = window.get_compositor_private () as WindowActor;
            if (actor == null)
                return null;

            actor.hide ();

            var clone = new SafeWindowClone (window, true);
            clone.x = actor.x;
            clone.y = actor.y;

            window_clones.add_child (clone);

            var icon = new WindowIcon (window, dock_settings.IconSize, ui_scale_factor, true);
            icon.reactive = true;
            icon.opacity = 100;
            icon.x_expand = true;
            icon.y_expand = true;
            icon.x_align = ActorAlign.CENTER;
            icon.y_align = ActorAlign.CENTER;
            icon.button_release_event.connect (clicked_icon);

            dock.add_child (icon);

            return icon;
        }

        void dim_windows () {
            foreach (var actor in window_clones.get_children ()) {
                unowned SafeWindowClone clone = (SafeWindowClone) actor;

                actor.save_easing_state ();
                actor.set_easing_duration (250);
                actor.set_easing_mode (AnimationMode.EASE_IN_OUT_QUART);

                if (clone.window == current_window.window) {
                    window_clones.set_child_above_sibling (actor, null);
                    actor.remove_effect_by_name ("brightness");
                    actor.z_position = 0;
                } else {
                    if (actor.get_effect ("brightness") == null) {
                        var brightness_effect = new BrightnessContrastEffect ();
                        brightness_effect.set_brightness (DIM_WINDOW_BRIGHTNESS);
                        actor.add_effect_with_name ("brightness", brightness_effect);
                    }

                    actor.z_position = -100;
                }

                actor.restore_easing_state ();
            }

            foreach (var actor in dock.get_children ()) {
                unowned WindowIcon icon = (WindowIcon) actor;
                icon.save_easing_state ();
                icon.set_easing_duration (100);
                icon.set_easing_mode (AnimationMode.LINEAR);

                if (icon == current_window)
                    icon.opacity = 255;
                else
                    icon.opacity = 100;

                icon.restore_easing_state ();
            }
        }

        /**
         * Adds the suitable windows on the given workspace to the switcher
         *
         * @return whether the switcher should actually be started or if there are
         *         not enough windows
         */
        bool collect_windows (Workspace workspace) {
#if HAS_MUTTER330
            var display = workspace.get_display ();
#else
            var screen = workspace.get_screen ();
            var display = screen.get_display ();
#endif

            var windows = display.get_tab_list (TabList.NORMAL, workspace);
            var current = display.get_tab_current (TabList.NORMAL, workspace);

            if (windows.length () < 1)
                return false;

            if (windows.length () == 1) {
                var window = windows.data;
                if (window.minimized)
                    window.unminimize ();
                else
#if HAS_MUTTER330
                    Utils.bell (display);
#else
                    Utils.bell (screen);
#endif

                window.activate (display.get_current_time ());

                return false;
            }

            foreach (var window in windows) {
                var clone = add_window (window);
                if (window == current)
                    current_window = clone;
            }

            clone_sort_order = window_clones.get_children ().copy ();

            if (current_window == null)
                current_window = (WindowIcon) dock.get_child_at_index (0);

            // hide the others
#if HAS_MUTTER330
            unowned GLib.List<Meta.WindowActor> window_actors = display.get_window_actors ();
#else
            unowned GLib.List<Meta.WindowActor> window_actors = screen.get_window_actors ();
#endif
            foreach (unowned Meta.WindowActor actor in window_actors) {
                if (actor.is_destroyed ())
                    continue;

                unowned Meta.Window window = actor.get_meta_window ();
                var type = window.window_type;

                if (type != WindowType.DOCK
                    && type != WindowType.DESKTOP
                    && type != WindowType.NOTIFICATION)
                    actor.hide ();
                var behavior_settings = new GLib.Settings (Config.SCHEMA + ".behavior");
                if (window.title in behavior_settings.get_strv ("dock-names")
                    && type == WindowType.DOCK) {
                    dock_window = actor;
                    dock_window.hide ();
                }
            }

            return true;
        }

        WindowIcon next_window (Workspace workspace, bool backward) {
            Actor actor;
            if (!backward) {
                actor = current_window.get_next_sibling ();
                if (actor == null)
                    actor = dock.get_first_child ();
            } else {
                actor = current_window.get_previous_sibling ();
                if (actor == null)
                    actor = dock.get_last_child ();
            }

            return (WindowIcon) actor;
        }

        /**
         * copied from gnome-shell, finds the primary modifier in the mask and saves it
         * to our modifier_mask field
         *
         * @param mask The modifier mask to extract the primary one from
         */
        void set_primary_modifier (uint mask) {
            if (mask == 0)
                modifier_mask = 0;
            else {
                modifier_mask = 1;
                while (mask > 1) {
                    mask >>= 1;
                    modifier_mask <<= 1;
                }
            }
        }

        /**
         * Counts the launcher items to get an estimate of the window size
         */
        void update_n_dock_items (File folder, File? other_file, FileMonitorEvent event) {
            if (event != FileMonitorEvent.CREATED && event != FileMonitorEvent.DELETED)
                return;

            var count = 0;

            try {
                var children = folder.enumerate_children ("", 0);
                while (children.next_file () != null)
                    count++;

            } catch (Error e) { warning (e.message); }

            n_dock_items = count;
        }

        Gdk.ModifierType get_current_modifiers () {
            Gdk.ModifierType modifiers;
            double[] axes = {};
            Gdk.Display.get_default ().get_device_manager ().get_client_pointer ()
                .get_state (Gdk.get_default_root_window (), axes, out modifiers);

            return modifiers;
        }
    }
}
