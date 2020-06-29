//
//  Copyright (C) 2017 Adam Bieńkowski
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

public class Gala.Plugins.PIP.PopupWindow : Clutter.Actor {
    private int button_size;
    private int container_margin;
    private const int SHADOW_SIZE = 100;
    private const uint FADE_OUT_TIMEOUT = 200;
    private const float MINIMUM_SCALE = 0.1f;
    private const float MAXIMUM_SCALE = 1.0f;
    private const int SCREEN_MARGIN = 0;

    public signal void closed ();

    public Gala.WindowManager wm { get; construct; }
    public Meta.WindowActor window_actor { get; construct; }

    private bool dynamic_container = false;

    private Clutter.Actor clone;
    private Clutter.Actor container;
    private Clutter.Actor close_button;
    private Clutter.Actor resize_button;
    private Clutter.Actor resize_handle;
    private Clutter.ClickAction close_action;
    private Clutter.DragAction resize_action;
    private MoveAction move_action;

    private bool dragging = false;
    private bool clicked = false;

    private int x_offset_press = 0;
    private int y_offset_press = 0;

    private float begin_resize_width = 0.0f;
    private float begin_resize_height = 0.0f;

    static unowned Meta.Window? previous_focus = null;

    // From https://opensourcehacker.com/2011/12/01/calculate-aspect-ratio-conserving-resize-for-images-in-javascript/
    static void calculate_aspect_ratio_size_fit (float src_width, float src_height, float max_width, float max_height,
        out float width, out float height) {
        float ratio = float.min (max_width / src_width, max_height / src_height);
        width = src_width * ratio;
        height = src_height * ratio;
    }

    static bool get_window_is_normal (Meta.Window window) {
        var window_type = window.get_window_type ();
        return window_type == Meta.WindowType.NORMAL
            || window_type == Meta.WindowType.DIALOG
            || window_type == Meta.WindowType.MODAL_DIALOG;
    }

    static void get_current_cursor_position (out int x, out int y) {
        Gdk.Display.get_default ().get_device_manager ().get_client_pointer ().get_position (null, out x, out y);
    }

    public PopupWindow (Gala.WindowManager wm, Meta.WindowActor window_actor) {
        Object (wm: wm, window_actor: window_actor);
    }

    construct {
        var scale = Utils.get_ui_scaling_factor ();
        button_size = 36 * scale;
        container_margin = button_size / 2;

        reactive = true;

        set_pivot_point (0.5f, 0.5f);
        set_easing_mode (Clutter.AnimationMode.EASE_IN_QUAD);

        var window = window_actor.get_meta_window ();
        window.unmanaged.connect (on_close_click_clicked);
        window.notify["appears-focused"].connect (() => {
            Idle.add (() => {
                update_window_focus ();
                return false;
            });
        });

        clone = new Clutter.Clone (window_actor);

        move_action = new MoveAction ();
        move_action.drag_begin.connect (on_move_begin);
        move_action.drag_end.connect (on_move_end);
        move_action.move.connect (on_move);

        container = new Clutter.Actor ();
        container.reactive = true;
        container.set_scale (0.35f, 0.35f);
        container.add_effect (new ShadowEffect (SHADOW_SIZE, 2));
        container.add_child (clone);
        container.add_action (move_action);

        update_size ();
        update_container_position ();

        Meta.Rectangle monitor_rect;
        get_current_monitor_rect (out monitor_rect);

        float x_position, y_position;
        if (Clutter.get_default_text_direction () == Clutter.TextDirection.RTL) {
            x_position = SCREEN_MARGIN + monitor_rect.x;
        } else {
            x_position = monitor_rect.width + monitor_rect.x - SCREEN_MARGIN - width;
        }
        y_position = monitor_rect.height + monitor_rect.y - SCREEN_MARGIN - height;

        set_position (x_position, y_position);

        close_action = new Clutter.ClickAction ();
        close_action.clicked.connect (on_close_click_clicked);

        close_button = Gala.Utils.create_close_button ();
        close_button.opacity = 0;
        close_button.reactive = true;
        close_button.set_easing_duration (300);
        close_button.add_action (close_action);

        resize_action = new Clutter.DragAction ();
        resize_action.drag_begin.connect (on_resize_drag_begin);
        resize_action.drag_end.connect (on_resize_drag_end);
        resize_action.drag_motion.connect (on_resize_drag_motion);

        resize_handle = new Clutter.Actor ();
        resize_handle.set_size (button_size, button_size);
        resize_handle.set_pivot_point (0.5f, 0.5f);
        resize_handle.set_position (width - button_size, height - button_size);
        resize_handle.reactive = true;
        resize_handle.add_action (resize_action);

        resize_button = Utils.create_resize_button ();
        resize_button.set_pivot_point (0.5f, 0.5f);
        resize_button.set_position (width - button_size, height - button_size);
        resize_button.opacity = 0;
        resize_button.reactive = true;

        add_child (container);
        add_child (close_button);
        add_child (resize_button);
        add_child (resize_handle);

        window_actor.notify["allocation"].connect (on_allocation_changed);
        container.set_position (container_margin, container_margin);
        update_clone_clip ();
    }

    public override void show () {
        base.show ();

        opacity = 0;

        set_easing_duration (200);
        opacity = 255;

        set_easing_duration (0);
    }

    public override void hide () {
        opacity = 255;

        set_easing_duration (200);
        opacity = 0;

        set_easing_duration (0);

        ulong completed_id = 0UL;
        completed_id = transitions_completed.connect (() => {
            disconnect (completed_id);
            base.hide ();
        });
    }

    public override bool enter_event (Clutter.CrossingEvent event) {
        close_button.opacity = 255;

        resize_button.set_easing_duration (300);
        resize_button.opacity = 255;
        resize_button.set_easing_duration (0);
        return true;
    }

    public override bool leave_event (Clutter.CrossingEvent event) {
        close_button.opacity = 0;

        resize_button.set_easing_duration (300);
        resize_button.opacity = 0;
        resize_button.set_easing_duration (0);
        return true;
    }

#if HAS_MUTTER336
    public void set_container_clip (Graphene.Rect? container_clip) {
#else
    public void set_container_clip (Clutter.Rect? container_clip) {
#endif
        container.clip_rect = container_clip;
        dynamic_container = true;
        update_container_scale ();
        on_allocation_changed ();
    }

    private void on_move_begin () {
        int px, py;
        get_current_cursor_position (out px, out py);

        x_offset_press = (int)(px - x);
        y_offset_press = (int)(py - y);

        clicked = true;
        dragging = false;
    }

    private void on_move_end () {
        clicked = false;

        if (dragging) {
            update_screen_position ();
            dragging = false;
        } else {
            activate ();
        }
    }

    private void on_move () {
        if (!clicked) {
            return;
        }

        float motion_x, motion_y;
        move_action.get_motion_coords (out motion_x, out motion_y);

        x = (int)motion_x - x_offset_press;
        y = (int)motion_y - y_offset_press;

        if (!dragging) {
            dragging = true;
        }
    }

    private void on_resize_drag_begin (Clutter.Actor actor, float event_x, float event_y, Clutter.ModifierType type) {
        begin_resize_width = width;
        begin_resize_height = height;
    }

    private void on_resize_drag_end (Clutter.Actor actor, float event_x, float event_y, Clutter.ModifierType type) {
        reposition_resize_handle ();
        update_screen_position ();
    }

    private void on_resize_drag_motion (Clutter.Actor actor, float delta_x, float delta_y) {
        float press_x, press_y;
        resize_action.get_press_coords (out press_x, out press_y);

        int motion_x, motion_y;
        get_current_cursor_position (out motion_x, out motion_y);

        float diff_x = motion_x - press_x;
        float diff_y = motion_y - press_y;

        width = begin_resize_width + diff_x;
        height = begin_resize_height + diff_y;

        update_container_scale ();
        update_size ();
        reposition_resize_button ();
    }

    private void on_allocation_changed () {
        update_clone_clip ();
        update_size ();
        reposition_resize_button ();
        reposition_resize_handle ();
    }

    private void on_close_click_clicked () {
        set_easing_duration (FADE_OUT_TIMEOUT);

        opacity = 0;

        Clutter.Threads.Timeout.add (FADE_OUT_TIMEOUT, () => {
            closed ();
            return false;
        });
    }

    private void update_window_focus () {
#if HAS_MUTTER330
        unowned Meta.Window focus_window = wm.get_display ().get_focus_window ();
#else
        unowned Meta.Window focus_window = wm.get_screen ().get_display ().get_focus_window ();
#endif
        if ((focus_window != null && !get_window_is_normal (focus_window))
            || (previous_focus != null && !get_window_is_normal (previous_focus))) {
            previous_focus = focus_window;
            return;
        }

        var window = window_actor.get_meta_window ();
        if (window.appears_focused) {
            hide ();
        } else if (!window_actor.is_destroyed ()) {
            show ();
        }

        previous_focus = focus_window;
    }

    private void update_size () {
        if (dynamic_container) {
            float src_width = 0.0f, src_height = 0.0f;
            container.get_clip (null, null, out src_width, out src_height);
            width = (int)(src_width * container.scale_x + button_size);
            height = (int)(src_height * container.scale_y + button_size);
        } else {
            width = (int)(container.width * container.scale_x + button_size);
            height = (int)(container.height * container.scale_y + button_size);
        }
    }

    private void update_clone_clip () {
        var rect = window_actor.get_meta_window ().get_frame_rect ();

        float x_offset = rect.x - window_actor.x;
        float y_offset = rect.y - window_actor.y;
        clone.set_clip (x_offset, y_offset, rect.width, rect.height);
        clone.set_position (-x_offset, -y_offset);

        container.set_size (rect.width, rect.height);
    }

    private void update_container_scale () {
        float src_width = 1.0f, src_height = 1.0f;
        if (dynamic_container) {
            container.get_clip (null, null, out src_width, out src_height);
        } else {
            src_width = container.width;
            src_height = container.height;
        }

        float max_width = width - button_size;
        float max_height = height - button_size;

        float new_width, new_height;
        calculate_aspect_ratio_size_fit (
            src_width, src_height,
            max_width, max_height,
            out new_width, out new_height
        );

        float window_width = 1.0f, window_height = 1.0f;
        get_target_window_size (out window_width, out window_height);

        float new_scale_x = new_width / window_width;
        float new_scale_y = new_height / window_height;

        container.scale_x = new_scale_x.clamp (MINIMUM_SCALE, MAXIMUM_SCALE);
        container.scale_y = new_scale_y.clamp (MINIMUM_SCALE, MAXIMUM_SCALE);

        update_container_position ();
    }

    private void update_container_position () {
        if (dynamic_container) {
            float clip_x = 0.0f, clip_y = 0.0f;
            container.get_clip (out clip_x, out clip_y, null, null);
            container.x = (float)(-clip_x * container.scale_x + container_margin);
            container.y = (float)(-clip_y * container.scale_y + container_margin);
        }
    }

    private void update_screen_position () {
        Meta.Rectangle monitor_rect;
        get_current_monitor_rect (out monitor_rect);

        int monitor_x = monitor_rect.x;
        int monitor_y = monitor_rect.y;
        int monitor_width = monitor_rect.width;
        int monitor_height = monitor_rect.height;

        set_easing_duration (300);
        set_easing_mode (Clutter.AnimationMode.EASE_OUT_BACK);

        var screen_limit_start = SCREEN_MARGIN + monitor_x;
        var screen_limit_end = monitor_width + monitor_x - SCREEN_MARGIN - width;

        x = x.clamp (screen_limit_start, screen_limit_end);

        screen_limit_start = SCREEN_MARGIN + monitor_y;
        screen_limit_end = monitor_height + monitor_y - SCREEN_MARGIN - height;

        y = y.clamp (screen_limit_start, screen_limit_end);

        set_easing_mode (Clutter.AnimationMode.EASE_IN_QUAD);
        set_easing_duration (0);
    }

    private void reposition_resize_button () {
        resize_button.set_position (width - button_size, height - button_size);
    }

    private void reposition_resize_handle () {
        resize_handle.set_position (width - button_size, height - button_size);
    }

    private void get_current_monitor_rect (out Meta.Rectangle rect) {
#if HAS_MUTTER330
        var display = wm.get_display ();
        rect = display.get_monitor_geometry (display.get_current_monitor ());
#else
        var screen = wm.get_screen ();
        rect = screen.get_monitor_geometry (screen.get_current_monitor ());
#endif
    }

    private void get_target_window_size (out float width, out float height) {
        if (dynamic_container) {
            container.get_clip (null, null, out width, out height);
        } else if (clone.has_clip) {
            clone.get_clip (null, null, out width, out height);
        } else {
            width = clone.width;
            height = clone.height;
        }
    }

    private void activate () {
        var window = window_actor.get_meta_window ();
        window.activate (Clutter.get_current_event_time ());
    }
}
