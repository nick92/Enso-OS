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

namespace Gala
{
	public delegate void ObjectCallback (Object object);

	public class WindowActorClone : Clutter.Actor {
		public Meta.WindowActor window_actor { get; construct; }
		public Meta.Window window { get; construct; }

		public Clutter.Actor container { get; private set; }
		private Clutter.Clone clone;

		public WindowActorClone (Meta.WindowActor window_actor) {
			Object (window_actor: window_actor, window: window_actor.get_meta_window ());

			//clone = new Clutter.Clone (window_actor.get_texture ());
			clone = new SafeWindowClone (window);
			container = new Clutter.Actor ();
			container.add (clone);
			container.set_scale (0.3f, 0.3f);
			add (container);
			window_actor.notify["allocate"].connect (update_clone);
			update_clone ();

			var window_icon = new WindowIcon (window, 64);
			window_icon.set_position (container.width / 2 - window_icon.width / 2, container.height - window_icon.height / 2);
			add (window_icon);
		}

		private void update_clone ()
		{
			var rect = window_actor.get_meta_window ().get_frame_rect ();
			float x_offset = rect.x  - window_actor.x;
			float y_offset = rect.y  - window_actor.y;

			container.width = (float)(rect.width * container.scale_x);
			container.height = (float)(rect.height * container.scale_y);
			clone.set_position (-x_offset, -y_offset);
		}
	}

	public class EnsoWindowSwitcher: Actor
	{
		const int SPACING = 12;
		const int PADDING = 24;
		const int MIN_OFFSET = 32;
		const int INDICATOR_BORDER = 6;
		const double ANIMATE_SCALE = 0.8;

		public bool opened { get; private set; default = false; }

		public WindowManager wm { get; construct; }

		Gala.ModalProxy modal_proxy = null;
		Actor wrapper;
		Actor indicator;

		int modifier_mask;
		Meta.Screen screen;

		Gee.ArrayList<PreviewPage> pages;

		private WindowActorClone? current {
			get {
				return current_page.current;
			}
		}

		PreviewPage? current_page = null;
		Actor? background = null;

		public EnsoWindowSwitcher (WindowManager wm)
		{
			Object (wm: wm);
		}

		construct
		{
			screen = wm.get_screen ();
			pages = new Gee.ArrayList<PreviewPage> ();

			var layout = new FlowLayout (FlowOrientation.HORIZONTAL);
			layout.snap_to_grid = true;
			layout.column_spacing = layout.row_spacing = SPACING;

			wrapper = new Actor ();

			background = new Actor ();
			background.background_color = { 0, 0, 0, 150 };
			
			wrapper.reactive = true;
			wrapper.set_pivot_point (0.5f, 0.5f);
			wrapper.key_release_event.connect (key_relase_event);

			indicator = new Actor ();
			indicator.background_color = { 255, 255, 255, 150 };
			indicator.width = INDICATOR_BORDER;
			indicator.height = INDICATOR_BORDER;
			indicator.set_easing_duration (150);

			wrapper.add_child (background);
			wrapper.add_child (indicator);
		}

		[CCode (instance_pos = -1)]
	    public void handle_switch_windows (Display display, Screen screen, Window? window,
			KeyEvent? event, Meta.KeyBinding binding)
		{
			try{
				var settings = AlternateAltTabSettings.get_default ();
				var workspace = settings.all_workspaces ? null : screen.get_active_workspace ();

				// copied from gnome-shell, finds the primary modifier in the mask
				var mask = binding.get_mask ();
				if (mask == 0)
					modifier_mask = 0;
				else {
					modifier_mask = 1;
					while (mask > 1) {
						mask >>= 1;
						modifier_mask <<= 1;
					}
				}

				if (!opened) {
					collect_windows (display, workspace);
					open_switcher ();
					update_indicator_position ();
				}

				var binding_name = binding.get_name ();
				var backward = binding_name.has_suffix ("-backward");

				// FIXME for unknown reasons, switch-applications-backward won't be emitted, so we
				//       test manually if shift is held down
				if (binding_name == "switch-applications")
					backward = ((get_current_modifiers () & ModifierType.SHIFT_MASK) != 0);

				next_window (display, workspace, backward);
			}catch(Error ex){
				warning(ex.message);
			}
		}

		void collect_windows (Display display, Workspace? workspace)
		{
			var screen = wm.get_screen ();

			var windows = display.get_tab_list (TabList.NORMAL, workspace);
			var current_window = display.get_tab_current (TabList.NORMAL, workspace);

			pages.clear ();
			var page = new PreviewPage (screen);
			foreach (var window in windows) {
				var actor = get_actor_for_window (window);
				var clone = new WindowActorClone (actor);
				page.add_window_actor (clone);
				if (window == current_window) {
					page.current = clone;
				}
			}

			page.reallocate ();
			pages.add (page);
		}

		Meta.WindowActor? get_actor_for_window (Meta.Window window)
		{
			Meta.WindowActor? window_actor = null;
			unowned List<Meta.WindowActor> actors = Compositor.get_window_actors (wm.get_screen ());
			actors.@foreach ((actor) => {
				if (actor.get_meta_window () == window) {
					window_actor = actor;
					return;
				}
			});

			return window_actor;
		}

		void open_switcher ()
		{
			if (pages.size == 0) {
				return;
			}

			if (opened) {
				return;
			}

			if (current_page != null) {
				wrapper.remove_child (current_page);
			}

			current_page = pages[0];
			wrapper.add_child (current_page);

			var screen = wm.get_screen ();
			var settings = AlternateAltTabSettings.get_default ();

			if (settings.animate) {
				wrapper.opacity = 0;
			}

			int width, height;
			screen.get_size (out width, out height);
			wrapper.width = width;
			wrapper.height = height;

			background.width = width;
			background.height = height;

			wm.ui_group.insert_child_above (wrapper, null);

			wrapper.save_easing_state ();
			wrapper.set_easing_duration (200);
			wrapper.opacity = 255;
			wrapper.restore_easing_state ();

			modal_proxy = wm.push_modal ();
			modal_proxy.keybinding_filter = keybinding_filter;
			opened = true;

			wrapper.grab_key_focus ();

			// if we did not have the grab before the key was released, close immediately
			if ((get_current_modifiers () & modifier_mask) == 0)
				close_switcher (screen.get_display ().get_current_time ());
		}

		void close_switcher (uint32 time)
		{
			if (!opened)
				return;

			wm.pop_modal (modal_proxy);
			opened = false;

			ObjectCallback remove_actor = () => {
				wm.ui_group.remove_child (wrapper);
			};

			if (AlternateAltTabSettings.get_default ().animate) {
				wrapper.save_easing_state ();
				wrapper.set_easing_duration (100);
				wrapper.opacity = 0;

				var transition = wrapper.get_transition ("opacity");
				if (transition != null)
					transition.completed.connect (() => remove_actor (this));
				else
					remove_actor (this);

				wrapper.restore_easing_state ();
			} else {
				remove_actor (this);
			}

			if (current.window == null) {
				return;
			}

			var window = current.window;
			var workspace = window.get_workspace ();
			if (workspace != wm.get_screen ().get_active_workspace ())
				workspace.activate_with_focus (window, time);
			else
				window.activate (time);
		}

		void next_window (Display display, Workspace? workspace, bool backward)
		{
			current_page.next (backward);
			update_indicator_position ();
		}

		void update_indicator_position ()
		{
			float x, y;
			current.get_position (out x, out y);

			indicator.x = current_page.container.x + MIN_OFFSET + x - INDICATOR_BORDER;
			indicator.y = current_page.container.y + MIN_OFFSET + y - INDICATOR_BORDER;
			indicator.width = current.container.width + INDICATOR_BORDER * 2;
			indicator.height = current.container.height + INDICATOR_BORDER * 2;
		}

		bool key_relase_event (KeyEvent event)
		{
			if ((get_current_modifiers () & modifier_mask) == 0) {
				close_switcher (event.time);
				return true;
			}

			var settings = AlternateAltTabSettings.get_default ();
			var workspace = settings.all_workspaces ? null : screen.get_active_workspace ();
			var display = screen.get_display ();

			switch (event.keyval) {
				case Key.Escape:
					close_switcher (event.time);
					return true;
				case Key.Right:
					next_window (display, workspace, false);
					return true;
				case Key.Left:
					next_window (display, workspace, true);
					return true;
			}

			return false;
		}

		Gdk.ModifierType get_current_modifiers ()
		{
			Gdk.ModifierType modifiers;
			double[] axes = {};
			Gdk.Display.get_default ().get_device_manager ().get_client_pointer ()
				.get_state (Gdk.get_default_root_window (), axes, out modifiers);

			return modifiers;
		}

		bool keybinding_filter (KeyBinding binding)
		{
			// don't block any keybinding for the time being
			// return true for any keybinding that should be handled here.
			return false;
		}
	}
}
