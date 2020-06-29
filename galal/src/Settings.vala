//
//  Copyright (C) 2012 GardenGnome, Rico Tzschichholz, Tom Beckmann
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
    public class BehaviorSettings : Granite.Services.Settings
	{
		public bool dynamic_workspaces { get; set; }
		public bool edge_tiling { get; set; }
		public string panel_main_menu_action { get; set; }
		public string change_background_action { get; set; }
		public string settings_action { get; set; }
		public string toggle_recording_action { get; set; }
		public string overlay_action { get; set; }
		public string hotcorner_custom_command { get; set; }
		public string[] dock_names { get; set; }

		//public WindowOverviewType window_overview_type { get; set; }

		public ActionType hotcorner_topleft { get; set; }
		public ActionType hotcorner_topright { get; set; }
		public ActionType hotcorner_bottomleft { get; set; }
		public ActionType hotcorner_bottomright { get; set; }

		static BehaviorSettings? instance = null;

		private BehaviorSettings ()
		{
			base (Config.SCHEMA + ".behavior");
		}

		public static unowned BehaviorSettings get_default ()
		{
			if (instance == null)
				instance = new BehaviorSettings ();

			return instance;
		}
    }
    
    public class ShadowSettings : Granite.Services.Settings {
        public string[] menu { get; set; }
        public string[] normal_focused { get; set; }
        public string[] normal_unfocused { get; set; }
        public string[] dialog_focused { get; set; }
        public string[] dialog_unfocused { get; set; }

        static ShadowSettings? instance = null;

        private ShadowSettings () {
            base (Config.SCHEMA + ".shadows");
        }

        public static unowned ShadowSettings get_default () {
            if (instance == null)
                instance = new ShadowSettings ();

            return instance;
        }

        public Meta.ShadowParams get_shadowparams (string class_name) {
            string[] val;
            get (class_name, out val);

            if (val == null || int.parse (val[0]) < 1)
                return Meta.ShadowParams () {radius = 1, top_fade = 0, x_offset = 0, y_offset = 0, opacity = 0};

            return Meta.ShadowParams () {radius = int.parse (val[0]), top_fade = int.parse (val[1]),
                x_offset = int.parse (val[2]), y_offset = int.parse (val[3]), opacity = (uint8)int.parse (val[4])};
        }
    }

    public class AlternateAltTabSettings : Granite.Services.Settings
	{
		public bool all_workspaces { get; set; default = false; }
		public bool animate { get; set; default = true; }
		public bool always_on_primary_monitor { get; set; default = false; }
		public int icon_size { get; set; default = 128; }

		static AlternateAltTabSettings? instance = null;

		private AlternateAltTabSettings ()
		{
			base ("org.pantheon.desktop.gala.plugins.alternate-alt-tab");
		}

		public static AlternateAltTabSettings get_default ()
		{
			if (instance == null)
				instance = new AlternateAltTabSettings ();

			return instance;
		}
	}
}
