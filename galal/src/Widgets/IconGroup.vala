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
     * Container for WindowIconActors which takes care of the scaling and positioning.
     * It also decides whether to draw the container shape, a plus sign or an ellipsis.
     * Lastly it also includes the drawing code for the active highlight.
     */
    public class IconGroup : Actor {
        public const int SIZE = 64;

        const int PLUS_SIZE = 8;
        const int PLUS_WIDTH = 24;

        const int SHOW_CLOSE_BUTTON_DELAY = 200;

        /**
         * The group has been clicked. The MultitaskingView should consider activating
         * its workspace.
         */
        public signal void selected ();

        uint8 _backdrop_opacity = 0;
        /**
         * The opacity of the backdrop/highlight. Set by the active property setter.
         */
        protected uint8 backdrop_opacity {
            get {
                return _backdrop_opacity;
            }
            set {
                _backdrop_opacity = value;
                queue_redraw ();
            }
        }

        bool _active = false;
        /**
         * Fades in/out the backdrop/highlight
         */
        public bool active {
            get {
                return _active;
            }
            set {
                if (_active == value)
                    return;

                if (get_transition ("backdrop-opacity") != null)
                    remove_transition ("backdrop-opacity");

                _active = value;

                var transition = new PropertyTransition ("backdrop-opacity");
                transition.duration = 300;
                transition.remove_on_complete = true;
                transition.set_from_value (_active ? 0 : 40);
                transition.set_to_value (_active ? 40 : 0);

                add_transition ("backdrop-opacity", transition);
            }
        }

        DragDropAction drag_action;

        public Workspace workspace { get; construct; }

        Actor? prev_parent = null;
        Actor close_button;
        Actor icon_container;
        Cogl.Material dummy_material;

        uint show_close_button_timeout = 0;

        public IconGroup (Workspace workspace) {
            Object (workspace: workspace);
        }

        construct {
            var scale = InternalUtils.get_ui_scaling_factor ();
            var size = SIZE * scale;

            width = size;
            height = size;
            reactive = true;

            var canvas = new Canvas ();
            canvas.set_size (size, size);
            canvas.draw.connect (draw);
            content = canvas;

            dummy_material = new Cogl.Material ();

            drag_action = new DragDropAction (DragDropActionType.SOURCE | DragDropActionType.DESTINATION, "multitaskingview-window");
            drag_action.actor_clicked.connect (() => selected ());
            drag_action.drag_begin.connect (drag_begin);
            drag_action.drag_end.connect (drag_end);
            drag_action.drag_canceled.connect (drag_canceled);
            drag_action.notify["dragging"].connect (redraw);
            add_action (drag_action);

            icon_container = new Actor ();
            icon_container.width = width;
            icon_container.height = height;

            add_child (icon_container);

            close_button = Utils.create_close_button ();
            close_button.x = -Math.floorf (close_button.width * 0.4f);
            close_button.y = -Math.floorf (close_button.height * 0.4f);
            close_button.opacity = 0;
            close_button.reactive = true;
            close_button.visible = false;
            close_button.set_easing_duration (200);

            // block propagation of button presses on the close button, otherwise
            // the click action on the icon group will act weirdly
            close_button.button_press_event.connect (() => { return true; });

            add_child (close_button);

            var close_click = new ClickAction ();
            close_click.clicked.connect (close);
            close_button.add_action (close_click);

            icon_container.actor_removed.connect_after (redraw);
        }

        ~IconGroup () {
            icon_container.actor_removed.disconnect (redraw);
        }

        public override bool enter_event (CrossingEvent event) {
            toggle_close_button (true);
            return false;
        }

        public override bool leave_event (CrossingEvent event) {
            if (!contains (event.related))
                toggle_close_button (false);

            return false;
        }

        /**
         * Requests toggling the close button. If show is true, a timeout will be set after which
         * the close button is shown, if false, the close button is hidden and the timeout is removed,
         * if it exists. The close button may not be shown even though requested if the workspace has
         * no windows or workspaces aren't set to be dynamic.
         *
         * @param show Whether to show the close button
         */
        void toggle_close_button (bool show) {
            // don't display the close button when we don't have dynamic workspaces
            // or when there are no windows on us. For one, our method for closing
            // wouldn't work anyway without windows and it's also the last workspace
            // which we don't want to have closed if everything went correct
            if (!Prefs.get_dynamic_workspaces () || icon_container.get_n_children () < 1)
                return;

            if (show_close_button_timeout != 0) {
                Source.remove (show_close_button_timeout);
                show_close_button_timeout = 0;
            }

            if (show) {
                show_close_button_timeout = Timeout.add (SHOW_CLOSE_BUTTON_DELAY, () => {
                    close_button.visible = true;
                    close_button.opacity = 255;
                    show_close_button_timeout = 0;
                    return false;
                });
                return;
            }

            close_button.opacity = 0;
            var transition = get_transition ("opacity");
            if (transition != null)
                transition.completed.connect (() => {
                    close_button.visible = false;
                });
            else
                close_button.visible = false;
        }

        /**
         * Override the paint handler to draw our backdrop if necessary
         */
#if HAS_MUTTER336
        public override void paint (Clutter.PaintContext context) {
#else
        public override void paint () {
#endif
            if (backdrop_opacity < 1 || drag_action.dragging) {
#if HAS_MUTTER336
                base.paint (context);
#else
                base.paint ();
#endif

                return;
            }

            var scale = InternalUtils.get_ui_scaling_factor ();
            var width = 100 * scale;
            var x = ((SIZE * scale) - width) / 2;
            var y = -10;
            var height = WorkspaceClone.BOTTOM_OFFSET * scale;

#if HAS_MUTTER336
            Cogl.VertexP2T2C4 vertices[4];
            vertices[0] = { x, y + height, 0, 1, 255, 255, 255, backdrop_opacity };
            vertices[1] = { x, y, 0, 0, 0, 0, 0, 0 };
            vertices[2] = { x + width, y + height, 1, 1, 255, 255, 255, backdrop_opacity };
            vertices[3] = { x + width, y, 1, 0, 0, 0, 0, 0 };

            var primitive = new Cogl.Primitive.p2t2c4 (context.get_framebuffer ().get_context (), Cogl.VerticesMode.TRIANGLE_STRIP, vertices);
            var pipeline = new Cogl.Pipeline (context.get_framebuffer ().get_context ());
            primitive.draw (context.get_framebuffer (), pipeline);
#else
            var color_top = Cogl.Color.from_4ub (0, 0, 0, 0);
            var color_bottom = Cogl.Color.from_4ub (255, 255, 255, backdrop_opacity);
            color_bottom.premultiply ();

            Cogl.TextureVertex vertices[4];
            vertices[0] = { x, y, 0, 0, 0, color_top };
            vertices[1] = { x, y + height, 0, 0, 1, color_bottom };
            vertices[2] = { x + width, y + height, 0, 1, 1, color_bottom };
            vertices[3] = { x + width, y, 0, 1, 0, color_top };

            // for some reason cogl will try mapping the textures of the children
            // to the cogl_polygon call. We can fix this and force it to use our
            // color by setting a different material with no properties.
            Cogl.set_source (dummy_material);
            Cogl.polygon (vertices, true);
#endif
#if HAS_MUTTER336
                base.paint (context);
#else
                base.paint ();
#endif
        }

        /**
         * Remove all currently added WindowIconActors
         */
        public void clear () {
            icon_container.destroy_all_children ();
        }

        /**
         * Creates a WindowIconActor for the given window and adds it to the group
         *
         * @param window    The MetaWindow for which to create the WindowIconActor
         * @param no_redraw If you add multiple windows at once you may want to consider
         *                  settings this to true and when done calling redraw() manually
         * @param temporary Mark the WindowIconActor as temporary. Used for windows dragged over
         *                  the group.
         */
        public void add_window (Window window, bool no_redraw = false, bool temporary = false) {
            var new_window = new WindowIconActor (window);

            new_window.save_easing_state ();
            new_window.set_easing_duration (0);
            new_window.set_position (32, 32);
            new_window.restore_easing_state ();
            new_window.temporary = temporary;

            icon_container.add_child (new_window);

            if (!no_redraw)
                redraw ();
        }

        /**
         * Remove the WindowIconActor for a MetaWindow from the group
         *
         * @param animate Whether to fade the icon out before removing it
         */
        public void remove_window (Window window, bool animate = true) {
            foreach (var child in icon_container.get_children ()) {
                unowned WindowIconActor w = (WindowIconActor) child;
                if (w.window == window) {
                    if (animate) {
                        w.set_easing_mode (AnimationMode.LINEAR);
                        w.set_easing_duration (200);
                        w.opacity = 0;

                        var transition = w.get_transition ("opacity");
                        if (transition != null) {
                            transition.completed.connect (() => {
                                w.destroy ();
                            });
                        } else {
                            w.destroy ();
                        }

                    } else
                        w.destroy ();

                    // don't break here! If people spam hover events and we animate
                    // removal, we can actually multiple instances of the same window icon
                }
            }
        }

        /**
         * Sets a hovered actor for the drag action.
         */
        public void set_hovered_actor (Actor actor) {
            drag_action.hovered = actor;
        }

        /**
         * Trigger a redraw
         */
        public void redraw () {
            content.invalidate ();
        }

        /**
         * Close handler. We close the workspace by deleting all the windows on it.
         * That way the workspace won't be deleted if windows decide to ignore the
         * delete signal
         */
        void close () {
#if HAS_MUTTER330
            var time = workspace.get_display ().get_current_time ();
#else
            var time = workspace.get_screen ().get_display ().get_current_time ();
#endif
            foreach (var window in workspace.list_windows ()) {
                var type = window.window_type;
                if (!window.is_on_all_workspaces () && (type == WindowType.NORMAL
                    || type == WindowType.DIALOG || type == WindowType.MODAL_DIALOG))
                    window.@delete (time);
            }
        }

        /**
         * Draw the background or plus sign and do layouting. We won't lose performance here
         * by relayouting in the same function, as it's only ever called when we invalidate it.
         */
        bool draw (Cairo.Context cr) {
            var scale = InternalUtils.get_ui_scaling_factor ();

            cr.set_operator (Cairo.Operator.CLEAR);
            cr.paint ();
            cr.set_operator (Cairo.Operator.OVER);

            var n_windows = icon_container.get_n_children ();

            // single icon => big icon
            if (n_windows == 1) {
                var icon = (WindowIconActor) icon_container.get_child_at_index (0);
                icon.place (0, 0, 64);

                return false;
            }

            // more than one => we need a folder
            Granite.Drawing.Utilities.cairo_rounded_rectangle (
                cr,
                0.5 * scale,
                0.5 * scale,
                (int) width - (1 * scale),
                (int) height - (1 * scale),
                5 * scale
            );

            if (drag_action.dragging) {
                const double BG_COLOR = 53.0 / 255.0;
                cr.set_source_rgba (BG_COLOR, BG_COLOR, BG_COLOR, 0.7);
            } else {
                cr.set_source_rgba (0, 0, 0, 0.1);
            }

            cr.fill_preserve ();

            cr.set_line_width (1 * scale);

            var grad = new Cairo.Pattern.linear (0, 0, 0, height);
            grad.add_color_stop_rgba (0.8, 0, 0, 0, 0);
            grad.add_color_stop_rgba (1.0, 1, 1, 1, 0.1);

            cr.set_source (grad);
            cr.stroke ();

            Granite.Drawing.Utilities.cairo_rounded_rectangle (
                cr,
                1.5 * scale,
                1.5 * scale,
                (int) width - (3 * scale),
                (int) height - (3 * scale),
                5 * scale
            );

            cr.set_source_rgba (0, 0, 0, 0.3);
            cr.stroke ();

            // it's not safe to to call meta_workspace_index() here, we may be still animating something
            // while the workspace is already gone, which would result in a crash.
#if HAS_MUTTER330
            unowned Meta.WorkspaceManager manager = workspace.get_display ().get_workspace_manager ();
            int workspace_index = 0;
            for (int i = 0; i < manager.get_n_workspaces (); i++) {
                if (manager.get_workspace_by_index (i) == workspace) {
                    workspace_index = i;
                    break;
                }
            }
#else
            var screen = workspace.get_screen ();
            var workspace_index = screen.get_workspaces ().index (workspace);
#endif

            if (n_windows < 1) {
#if HAS_MUTTER330
                if (!Prefs.get_dynamic_workspaces ()
                    || workspace_index != manager.get_n_workspaces () - 1)
                    return false;
#else
                if (!Prefs.get_dynamic_workspaces ()
                    || workspace_index != screen.get_n_workspaces () - 1)
                    return false;
#endif

                var buffer = new Granite.Drawing.BufferSurface (SIZE * scale, SIZE * scale);
                var offset = (SIZE * scale) / 2 - (PLUS_WIDTH * scale) / 2;

                buffer.context.rectangle (PLUS_WIDTH / 2 * scale - PLUS_SIZE / 2 * scale + 0.5 + offset,
                    0.5 + offset,
                    PLUS_SIZE * scale - 1,
                    PLUS_WIDTH * scale - 1);

                buffer.context.rectangle (0.5 + offset,
                    PLUS_WIDTH / 2 * scale - PLUS_SIZE / 2 * scale + 0.5 + offset,
                    PLUS_WIDTH * scale - 1,
                    PLUS_SIZE * scale - 1);

                buffer.context.set_source_rgb (0, 0, 0);
                buffer.context.fill_preserve ();
                buffer.exponential_blur (5);

                buffer.context.set_source_rgb (1, 1, 1);
                buffer.context.set_line_width (1);
                buffer.context.stroke_preserve ();

                buffer.context.set_source_rgb (0.8, 0.8, 0.8);
                buffer.context.fill ();

                cr.set_source_surface (buffer.surface, 0, 0);
                cr.paint ();

                return false;
            }

            int size;
            if (n_windows < 5)
                size = 24;
            else
                size = 16;

            var n_tiled_windows = uint.min (n_windows, 9);
            var columns = (int) Math.ceil (Math.sqrt (n_tiled_windows));
            var rows = (int) Math.ceil (n_tiled_windows / (double) columns);

            int spacing = 6 * scale;

            var width = columns * (size * scale) + (columns - 1) * spacing;
            var height = rows * (size * scale) + (rows - 1) * spacing;
            var x_offset = SIZE * scale / 2 - width / 2;
            var y_offset = SIZE * scale / 2 - height / 2;

            var show_ellipsis = false;
            var n_shown_windows = n_windows;
            // make place for an ellipsis
            if (n_shown_windows > 9) {
                n_shown_windows = 8;
                show_ellipsis = true;
            }

            var x = x_offset;
            var y = y_offset;
            for (var i = 0; i < n_windows; i++) {
                var window = (WindowIconActor) icon_container.get_child_at_index (i);

                // draw an ellipsis at the 9th position if we need one
                if (show_ellipsis && i == 8) {
                    int top_offset = 10 * scale;
                    int left_offset = 2 * scale;
                    int radius = 2 * scale;
                    int dot_spacing = 3 * scale;
                    cr.arc (left_offset + x, y + top_offset, radius, 0, 2 * Math.PI);
                    cr.arc (left_offset + x + radius + dot_spacing, y + top_offset, radius, 0, 2 * Math.PI);
                    cr.arc (left_offset + x + radius * 2 + dot_spacing * 2, y + top_offset, radius, 0, 2 * Math.PI);

                    cr.set_source_rgb (0.3, 0.3, 0.3);
                    cr.fill ();
                }

                if (i >= n_shown_windows) {
                    window.visible = false;
                    continue;
                }

                window.place (x, y, size);

                x += (size * scale) + spacing;
                if (x + (size * scale) >= SIZE * scale) {
                    x = x_offset;
                    y += (size * scale) + spacing;
                }
            }

            return false;
        }

        Actor drag_begin (float click_x, float click_y) {
#if HAS_MUTTER330
            unowned Meta.WorkspaceManager manager = workspace.get_display ().get_workspace_manager ();
            if (icon_container.get_n_children () < 1 &&
                Prefs.get_dynamic_workspaces () &&
                workspace.index () == manager.get_n_workspaces () - 1) {
                return null;
            }
#else
            unowned Screen screen = workspace.get_screen ();
            if (icon_container.get_n_children () < 1 &&
                Prefs.get_dynamic_workspaces () &&
                workspace.index () == screen.get_n_workspaces () - 1) {
                return null;
            }
#endif

            float abs_x, abs_y;
            float prev_parent_x, prev_parent_y;

            prev_parent = get_parent ();
            prev_parent.get_transformed_position (out prev_parent_x, out prev_parent_y);

            var stage = get_stage ();
            var container = prev_parent as IconGroupContainer;
            if (container != null) {
                container.remove_group_in_place (this);
                container.reset_thumbs (0);
            } else {
                prev_parent.remove_child (this);
            }

            stage.add_child (this);

            get_transformed_position (out abs_x, out abs_y);
            set_position (abs_x + prev_parent_x, abs_y + prev_parent_y);

            close_button.opacity = 0;

            return this;
        }

        void drag_end (Actor destination) {
            if (destination is WorkspaceInsertThumb) {
                get_parent ().remove_child (this);

                unowned WorkspaceInsertThumb inserter = (WorkspaceInsertThumb) destination;
#if HAS_MUTTER330
                unowned Meta.WorkspaceManager manager = workspace.get_display ().get_workspace_manager ();
                manager.reorder_workspace (workspace, inserter.workspace_index);
#else
                workspace.get_screen ().reorder_workspace (workspace, inserter.workspace_index);
#endif

                restore_group ();
            } else {
                drag_canceled ();
            }
        }

        void drag_canceled () {
            get_parent ().remove_child (this);
            restore_group ();
        }

        void restore_group () {
            var container = prev_parent as IconGroupContainer;
            if (container != null) {
                container.add_group (this);
                container.request_reposition (false);
                container.reset_thumbs (WorkspaceInsertThumb.EXPAND_DELAY);
            }
        }
    }
}
