//
//  Copyright (C) 2014 Tom Beckmann
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
    /**
     * Utility class which adds a border and a shadow to a Background
     */
    class FramedBackground : BackgroundManager {
#if HAS_MUTTER336
        private Cogl.Pipeline pipeline;
#endif

#if HAS_MUTTER330
        public FramedBackground (Display display) {
            Object (display: display, monitor_index: display.get_primary_monitor (), control_position: false);
        }
#else
        public FramedBackground (Screen screen) {
            Object (screen: screen, monitor_index: screen.get_primary_monitor (), control_position: false);
        }
#endif

        construct {
#if HAS_MUTTER336
            pipeline = new Cogl.Pipeline (Clutter.get_default_backend ().get_cogl_context ());
#endif
#if HAS_MUTTER330
            var primary = display.get_primary_monitor ();
            var monitor_geom = display.get_monitor_geometry (primary);
#else
            var primary = screen.get_primary_monitor ();
            var monitor_geom = screen.get_monitor_geometry (primary);
#endif

            var effect = new ShadowEffect (40, 5);
            effect.css_class = "workspace";
            add_effect (effect);
        }

#if HAS_MUTTER336
        public override void paint (Clutter.PaintContext context) {
            base.paint (context);

            pipeline.set_color4ub (0, 0, 0, 100);
            var path = new Cogl.Path ();
            path.rectangle (0, 0, width, height);
            context.get_framebuffer ().stroke_path (pipeline, path);

            path = new Cogl.Path ();
            pipeline.set_color4ub (255, 255, 255, 25);
            path.rectangle (0, 0, width, height);
            context.get_framebuffer ().stroke_path (pipeline, path);
        }
#else
        public override void paint () {
            base.paint ();

            Cogl.set_source_color4ub (0, 0, 0, 100);
            var path = new Cogl.Path ();
            path.rectangle (0, 0, width, height);
            path.stroke ();

            Cogl.set_source_color4ub (255, 255, 255, 25);
            path.rectangle (0.5f, 0.5f, width - 1, height - 1);
            path.stroke ();
        }
#endif
    }

    /**
     * This is the container which manages a clone of the background which will
     * be scaled and animated inwards, a WindowCloneContainer for the windows on
     * this workspace and also holds the instance for this workspace's IconGroup.
     * The latter is not added to the WorkspaceClone itself though but to a container
     * of the MultitaskingView.
     */
    public class WorkspaceClone : Actor {
        /**
         * The offset of the scaled background to the bottom of the monitor bounds
         */
        public const int BOTTOM_OFFSET = 100;

        /**
         * The offset of the scaled background to the top of the monitor bounds
         */
        const int TOP_OFFSET = 20;

        /**
         * The amount of time a window has to be over the WorkspaceClone while in drag
         * before we activate the workspace.
         */
        const int HOVER_ACTIVATE_DELAY = 400;

        /**
         * A window has been selected, the MultitaskingView should consider activating
         * and closing the view.
         */
        public signal void window_selected (Window window);

        /**
         * The background has been selected. Switch to that workspace.
         *
         * @param close_view If the MultitaskingView should also consider closing itself
         *                   after switching.
         */
        public signal void selected (bool close_view);

        public Workspace workspace { get; construct; }
        public IconGroup icon_group { get; private set; }
        public WindowCloneContainer window_container { get; private set; }

        bool _active = false;
        /**
         * If this WorkspaceClone is currently the active one. Also sets the active
         * state on its IconGroup.
         */
        public bool active {
            get {
                return _active;
            }
            set {
                _active = value;
                icon_group.active = value;
            }
        }

        BackgroundManager background;
        bool opened;

        uint hover_activate_timeout = 0;

        public WorkspaceClone (Workspace workspace) {
            Object (workspace: workspace);
        }

        construct {
            opened = false;

#if HAS_MUTTER330
            unowned Display display = workspace.get_display ();
            var monitor_geometry = display.get_monitor_geometry (display.get_primary_monitor ());
#else
            unowned Screen screen = workspace.get_screen ();
            var monitor_geometry = screen.get_monitor_geometry (screen.get_primary_monitor ());
#endif

#if HAS_MUTTER330
            background = new FramedBackground (display);
#else
            background = new FramedBackground (screen);
#endif
            background.reactive = true;
            background.button_press_event.connect (() => {
                selected (true);
                return false;
            });

            window_container = new WindowCloneContainer ();
            window_container.window_selected.connect ((w) => { window_selected (w); });
            window_container.set_size (monitor_geometry.width, monitor_geometry.height);
#if HAS_MUTTER330
            display.restacked.connect (window_container.restack_windows);
#else
            screen.restacked.connect (window_container.restack_windows);
#endif

            icon_group = new IconGroup (workspace);
            icon_group.selected.connect (() => {
#if HAS_MUTTER330
                if (workspace == display.get_workspace_manager ().get_active_workspace ())
                    Utils.bell (display);
                else
                    selected (false);
#else
                if (workspace == screen.get_active_workspace ())
                    Utils.bell (screen);
                else
                    selected (false);
#endif
            });

            var icons_drop_action = new DragDropAction (DragDropActionType.DESTINATION, "multitaskingview-window");
            icon_group.add_action (icons_drop_action);

            var background_drop_action = new DragDropAction (DragDropActionType.DESTINATION, "multitaskingview-window");
            background.add_action (background_drop_action);
            background_drop_action.crossed.connect ((target, hovered) => {
                if (!hovered && hover_activate_timeout != 0) {
                    Source.remove (hover_activate_timeout);
                    hover_activate_timeout = 0;
                    return;
                }

                if (hovered && hover_activate_timeout == 0) {
                    hover_activate_timeout = Timeout.add (HOVER_ACTIVATE_DELAY, () => {
                        selected (false);
                        hover_activate_timeout = 0;
                        return false;
                    });
                }
            });

#if HAS_MUTTER330
            display.window_entered_monitor.connect (window_entered_monitor);
            display.window_left_monitor.connect (window_left_monitor);
#else
            screen.window_entered_monitor.connect (window_entered_monitor);
            screen.window_left_monitor.connect (window_left_monitor);
#endif
            workspace.window_added.connect (add_window);
            workspace.window_removed.connect (remove_window);

            add_child (background);
            add_child (window_container);

            // add existing windows
            var windows = workspace.list_windows ();
            foreach (var window in windows) {
#if HAS_MUTTER330
                if (window.window_type == WindowType.NORMAL
                    && !window.on_all_workspaces
                    && window.get_monitor () == display.get_primary_monitor ()) {
                    window_container.add_window (window);
                    icon_group.add_window (window, true);
                }
#else
                if (window.window_type == WindowType.NORMAL
                    && !window.on_all_workspaces
                    && window.get_monitor () == screen.get_primary_monitor ()) {
                    window_container.add_window (window);
                    icon_group.add_window (window, true);
                }
#endif
            }

            var listener = WindowListener.get_default ();
            listener.window_no_longer_on_all_workspaces.connect (add_window);
        }

        ~WorkspaceClone () {
#if HAS_MUTTER330
            unowned Meta.Display display = workspace.get_display ();

            display.restacked.disconnect (window_container.restack_windows);

            display.window_entered_monitor.disconnect (window_entered_monitor);
            display.window_left_monitor.disconnect (window_left_monitor);
#else
            unowned Screen screen = workspace.get_screen ();

            screen.restacked.disconnect (window_container.restack_windows);

            screen.window_entered_monitor.disconnect (window_entered_monitor);
            screen.window_left_monitor.disconnect (window_left_monitor);
#endif
            workspace.window_added.disconnect (add_window);
            workspace.window_removed.disconnect (remove_window);

            var listener = WindowListener.get_default ();
            listener.window_no_longer_on_all_workspaces.disconnect (add_window);

            background.destroy ();
        }

        /**
         * Add a window to the WindowCloneContainer and the IconGroup if it really
         * belongs to this workspace and this monitor.
         */
        void add_window (Window window) {
#if HAS_MUTTER330
            if (window.window_type != WindowType.NORMAL
                || window.get_workspace () != workspace
                || window.on_all_workspaces
                || window.get_monitor () != window.get_display ().get_primary_monitor ())
                return;
#else
            if (window.window_type != WindowType.NORMAL
                || window.get_workspace () != workspace
                || window.on_all_workspaces
                || window.get_monitor () != window.get_screen ().get_primary_monitor ())
                return;
#endif

            foreach (var child in window_container.get_children ())
                if (((WindowClone) child).window == window)
                    return;

            window_container.add_window (window);
            icon_group.add_window (window);
        }

        /**
         * Remove a window from the WindowCloneContainer and the IconGroup
         */
        void remove_window (Window window) {
            window_container.remove_window (window);
            icon_group.remove_window (window, opened);
        }

#if HAS_MUTTER330
        void window_entered_monitor (Display display, int monitor, Window window) {
            add_window (window);
        }

        void window_left_monitor (Display display, int monitor, Window window) {
            if (monitor == display.get_primary_monitor ())
                remove_window (window);
        }
#else
        void window_entered_monitor (Screen screen, int monitor, Window window) {
            add_window (window);
        }

        void window_left_monitor (Screen screen, int monitor, Window window) {
            if (monitor == screen.get_primary_monitor ())
                remove_window (window);
        }
#endif

        void update_size (Meta.Rectangle monitor_geometry) {
            if (window_container.width != monitor_geometry.width || window_container.height != monitor_geometry.height) {
                window_container.set_size (monitor_geometry.width, monitor_geometry.height);
                background.set_size (window_container.width, window_container.height);
            }
        }

        /**
         * Utility function to shrink a MetaRectangle on all sides for the given amount.
         * Negative amounts will scale it instead.
         *
         * @param amount The amount in px to shrink.
         */
        static inline void shrink_rectangle (ref Meta.Rectangle rect, int amount) {
            rect.x += amount;
            rect.y += amount;
            rect.width -= amount * 2;
            rect.height -= amount * 2;
        }

        /**
         * Animates the background to its scale, causes a redraw on the IconGroup and
         * makes sure the WindowCloneContainer animates its windows to their tiled layout.
         * Also sets the current_window of the WindowCloneContainer to the active window
         * if it belongs to this workspace.
         */
        public void open () {
            if (opened)
                return;

            opened = true;

            var scale_factor = InternalUtils.get_ui_scaling_factor ();
#if HAS_MUTTER330
            var display = workspace.get_display ();

            var monitor = display.get_monitor_geometry (display.get_primary_monitor ());
#else
            var screen = workspace.get_screen ();
            var display = screen.get_display ();

            var monitor = screen.get_monitor_geometry (screen.get_primary_monitor ());
#endif
            var scale = (float)(monitor.height - TOP_OFFSET * scale_factor - BOTTOM_OFFSET * scale_factor) / monitor.height;
            var pivotY = TOP_OFFSET * scale_factor / (monitor.height - monitor.height * scale);

            update_size (monitor);

            background.set_pivot_point (0.5f, pivotY);

            background.save_easing_state ();
            background.set_easing_duration (MultitaskingView.ANIMATION_DURATION);
            background.set_easing_mode (MultitaskingView.ANIMATION_MODE);
            background.set_scale (scale, scale);
            background.restore_easing_state ();

            Meta.Rectangle area = {
                (int)Math.floorf (monitor.x + monitor.width - monitor.width * scale) / 2,
                (int)Math.floorf (monitor.y + TOP_OFFSET * scale_factor),
                (int)Math.floorf (monitor.width * scale),
                (int)Math.floorf (monitor.height * scale)
            };
            shrink_rectangle (ref area, 32);

            window_container.padding_top = TOP_OFFSET * scale_factor;
            window_container.padding_left =
                window_container.padding_right = (int)(monitor.width - monitor.width * scale) / 2;
            window_container.padding_bottom = BOTTOM_OFFSET * scale_factor;

            icon_group.redraw ();

#if HAS_MUTTER330
            window_container.open (display.get_workspace_manager ().get_active_workspace () == workspace ? display.get_focus_window () : null);
#else
            window_container.open (screen.get_active_workspace () == workspace ? display.get_focus_window () : null);
#endif
        }

        /**
         * Close the view again by animating the background back to its scale and
         * the windows back to their old locations.
         */
        public void close () {
            if (!opened)
                return;

            opened = false;

            background.save_easing_state ();
            background.set_easing_duration (MultitaskingView.ANIMATION_DURATION);
            background.set_easing_mode (MultitaskingView.ANIMATION_MODE);
            background.set_scale (1, 1);
            background.restore_easing_state ();

            window_container.close ();
        }
    }
}
