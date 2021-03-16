/*
 * Copyright 2020 elementary, Inc (https://elementary.io)
 *           2014 Tom Beckmann
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

 public class Gala.NotificationStack : Object {
    public const string TRANSITION_ENTRY_NAME = "entry";
    public const string TRANSITION_MOVE_STACK_ID = "move-stack";

    // we need to keep a small offset to the top, because we clip the container to
    // its allocations and the close button would be off for the first notification
    private const int TOP_OFFSET = 2;
    private const int ADDITIONAL_MARGIN = 12;
    private const int MARGIN = 12;

    private const int WIDTH = 300;

    private int stack_y;
    private int stack_width;

    public Meta.Display display { get; construct; }

    private Gee.ArrayList<unowned Meta.WindowActor> notifications;

    public NotificationStack (Meta.Display display) {
        Object (display: display);
    }

    construct {
        notifications = new Gee.ArrayList<unowned Meta.WindowActor> ();

        Meta.MonitorManager.@get ().monitors_changed_internal.connect (update_stack_allocation);
        display.workareas_changed.connect (update_stack_allocation);
        update_stack_allocation ();
    }

    public void show_notification (Meta.WindowActor notification, bool animate) {
        notification.set_pivot_point (0.5f, 0.5f);

        unowned Meta.Window window = notification.get_meta_window ();
        window.stick ();

        var scale = Utils.get_ui_scaling_factor ();

        if (animate) {
            var opacity_transition = new Clutter.PropertyTransition ("opacity");
            opacity_transition.set_from_value (0);
            opacity_transition.set_to_value (255);

            var flip_transition = new Clutter.KeyframeTransition ("rotation-angle-x");
            flip_transition.set_from_value (90.0);
            flip_transition.set_to_value (0.0);
            flip_transition.set_key_frames ({ 0.6 });
            flip_transition.set_values ({ -10.0 });

            var entry = new Clutter.TransitionGroup () {
                duration = 400
            };
            entry.add_transition (opacity_transition);
            entry.add_transition (flip_transition);

            notification.transitions_completed.connect (() => notification.remove_all_transitions ());
            notification.add_transition (TRANSITION_ENTRY_NAME, entry);
        }

        /**
         * We will make space for the incomming notification
         * by shifting all current notifications by height
         * and then add it to the notifications list.
         */
        update_positions (animate, notification.height);

        var primary = display.get_primary_monitor ();
        var area = display.get_workspace_manager ().get_active_workspace ().get_work_area_for_monitor (primary);

        int notification_x_pos = area.x + area.width - window.get_frame_rect ().width;

        move_window (notification, notification_x_pos, stack_y + TOP_OFFSET + ADDITIONAL_MARGIN * scale);
        notifications.insert (0, notification);
    }

    private void update_stack_allocation () {
        var primary = display.get_primary_monitor ();
        var area = display.get_workspace_manager ().get_active_workspace ().get_work_area_for_monitor (primary);

        var scale = Utils.get_ui_scaling_factor ();
        stack_width = (WIDTH + MARGIN) * scale;

        stack_y = area.y;
    }

    private void update_positions (bool animate, float add_y = 0.0f) {
        var scale = Utils.get_ui_scaling_factor ();
        var y = stack_y + TOP_OFFSET + add_y + ADDITIONAL_MARGIN * scale;
        var i = notifications.size;
        var delay_step = i > 0 ? 150 / i : 0;
        foreach (var actor in notifications) {
            if (animate) {
                actor.save_easing_state ();
                actor.set_easing_mode (Clutter.AnimationMode.EASE_OUT_BACK);
                actor.set_easing_duration (200);
                actor.set_easing_delay ((i--) * delay_step);
            }

            move_window (actor, -1, (int)y);

            if (animate) {
                actor.restore_easing_state ();
            }

            // For some reason get_transition doesn't work later when we need to restore it
            unowned Clutter.Transition? transition = actor.get_transition ("position");
            actor.set_data<Clutter.Transition?> (TRANSITION_MOVE_STACK_ID, transition);

            y += actor.height;
        }
    }

    public void destroy_notification (Meta.WindowActor notification, bool animate) {
        if (animate) {
            notification.save_easing_state ();
            notification.set_easing_duration (100);
            notification.set_easing_mode (Clutter.AnimationMode.EASE_IN_QUAD);
            notification.opacity = 0;

            notification.x += stack_width;
            notification.restore_easing_state ();
        } else {
            notification.opacity = 0;
            notification.x += stack_width;
        }

        notifications.remove (notification);
        update_positions (animate);
    }

    /**
     * This function takes care of properly updating both the actor
     * position and the actual window position.
     *
     * To enable animations for a window we first need to move it's frame
     * in the compositor and then calculate & apply the coordinates for the window
     * actor.
     */
    private static void move_window (Meta.WindowActor actor, int x, int y) {
        if (actor.is_destroyed ()) {
            return;
        }

        unowned Meta.Window window = actor.get_meta_window ();
        if (window == null) {
            return;
        }

        var rect = window.get_frame_rect ();

        window.move_frame (false, x != -1 ? x : rect.x, y != -1 ? y : rect.y);

        /**
         * move_frame does not guarantee that the frame rectangle
         * will be updated instantly, get the buffer rectangle.
         */
        rect = window.get_buffer_rect ();
        actor.set_position (rect.x - ((actor.width - rect.width) / 2), rect.y - ((actor.height - rect.height) / 2));
    }
}