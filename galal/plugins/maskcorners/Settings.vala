//
//  Copyright (C) 2015 Rory J Sanderson
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

namespace Gala.Plugins.MaskCorners {
    class Settings : Granite.Services.Settings {
        static Settings? instance = null;

        public static unowned Settings get_default () {
            if (instance == null)
                instance = new Settings ();

            return instance;
        }

        public bool enable { get; set; default = true; }
        public bool disable_on_fullscreen { get; set; default = true; }
        public bool only_on_primary { get; set; default = false; }

        Settings () {
            base (Config.SCHEMA + ".mask-corners");
        }
    }
}
