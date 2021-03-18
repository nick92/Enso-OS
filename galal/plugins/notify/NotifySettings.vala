//
//  Copyright (C) 2014 Gala Developers
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
//
//  Authored by: Marcus Wichelmann <admin@marcusw.de>
//

namespace Gala.Plugins.Notify {
    public class NotifySettings : Granite.Services.Settings {
        public bool do_not_disturb { get; set; }

        static NotifySettings? instance = null;

        private NotifySettings () {
            base (Config.SCHEMA + ".notifications");
        }

        public static unowned NotifySettings get_default () {
            if (instance == null)
                instance = new NotifySettings ();

            return instance;
        }
    }

    public class BehaviorSettings : Granite.Services.Settings
	{
		public bool dynamic_workspaces { get; set; }
		public bool edge_tiling { get; set; }
        public bool use_new_notifications { get; set; }
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
}
