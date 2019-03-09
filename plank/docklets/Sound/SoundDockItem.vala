//
//  Copyright (C) 2018 Faissal Bensefia
//
//  This file is part of Plank.
//
//  Plank is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Plank is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

using Plank;

namespace Docky
{
	public class SoundDockItem : DockletItem
	{
		private Gtk.Grid container;
		private Widgets.VolumeScale volume_scale;
		private Widgets.VolumeScale mic_scale;
		private PopoverWindow popover;

		/**
		 * {@inheritDoc}
		 */
		public SoundDockItem.with_dockitem_file (GLib.File file)
		{
			GLib.Object (Prefs: new DockItemPreferences.with_file (file));
		}

		construct
		{
			popover = new PopoverWindow ();
			container_widget ();
			popover.add_widget (container);
			
			Icon = "audio-volume-muted-panel";
			Text = _("No Sound");
		}

		~SoundDockItem ()
		{
			
		}

		string get_icon (double volume) 
		{
			if (volume <= 0) {// || this.volume_control.mute) {
				return "audio-volume-muted-panel";
			} else if (volume <= 0.3) {
				return "audio-volume-low-panel";
			} else if (volume <= 0.7) {
				return "audio-volume-medium-panel";
			} else {
				return "audio-volume-high-panel";
			}
		}

		void container_widget () 
		{
			container = new Gtk.Grid ();
			container.set_row_spacing (6);
			container.set_column_spacing (6);

			volume_scale = new Widgets.VolumeScale ("audio-volume-high-panel", true, 0.0, 100, 0.01);
			mic_scale = new Widgets.VolumeScale ("audio-input-microphone-high-panel", true, 0.0, 100, 0.01);

			//volume_scale.margin_start = 6;
            //volume_scale.active = !volume_control.mute;
			//volume_scale.notify["active"].connect (on_volume_switch_change);
			
			container.attach (mic_scale,0,0,1,1);
			container.attach (volume_scale,0,1,1,1);
			
		}

		void connect_events () 
		{
            volume_scale.scale_widget.value_changed.connect (() => {
                /*var vol = new Services.VolumeControl.Volume();
                var v = volume_scale.scale_widget.get_value () * max_volume;
                vol.volume = v.clamp (0.0, max_volume);
                vol.reason = Services.VolumeControl.VolumeReasons.USER_KEYPRESS;
                volume_control.volume = vol;
                volume_scale.icon = get_volume_icon (volume_scale.scale_widget.get_value ());*/
            });
		}

		void on_volume_switch_change () {
			/*if (volume_scale.active) {
				volume_control.set_mute (false);
			} else {
				volume_control.set_mute (true);
			}*/
		}

		protected override AnimationType on_clicked (PopupButton button, Gdk.ModifierType mod, uint32 event_time)
		{
			if (button == PopupButton.LEFT) {
				if(popover.visible) {
					popover.hide();
					return AnimationType.NONE;
				}
				int x, y;
				get_icon_location(out x, out y);
				//popover.set_text (now.format("time :" +"%a, %b %d %H:%M");
				popover.show_at (x,y,Gtk.PositionType.BOTTOM);
				container.show_all ();

				return AnimationType.LIGHTEN;
			}
			return AnimationType.NONE;
		}

		public override Gee.ArrayList<Gtk.MenuItem> get_menu_items ()
		{
			//unowned ClockPreferences prefs = (ClockPreferences) Prefs;
			var items = new Gee.ArrayList<Gtk.MenuItem> ();
			
			var settings_item = new Gtk.MenuItem.with_mnemonic (_("Open Sound Settings"));
			settings_item.activate.connect (() => {
				//prefs.ShowDigital = !prefs.ShowDigital;
				Process.spawn_command_line_async ("pavucontrol");
			});
			items.add (settings_item);
			
			return items;
		}
	}
}
