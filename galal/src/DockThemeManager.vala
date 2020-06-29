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

namespace Gala {
    /**
     * Provides access to a PlankDrawingDockTheme and PlankDockPrefereces
     */
    public class DockThemeManager : Object {
        static DockThemeManager? instance = null;

        public static unowned DockThemeManager get_default () {
            if (instance == null)
                instance = new DockThemeManager ();

            return instance;
        }

        Plank.DockPreferences? dock_settings = null;
        Plank.DockTheme? dock_theme = null;

        public signal void dock_theme_changed (Plank.DockTheme? old_theme,
            Plank.DockTheme new_theme);

        DockThemeManager () {
            dock_settings = new Plank.DockPreferences ("dock1");
            dock_settings.notify["Theme"].connect (load_dock_theme);
        }

        public Plank.DockTheme get_dock_theme () {
            if (dock_theme == null)
                load_dock_theme ();

            return dock_theme;
        }

        public Plank.DockPreferences get_dock_settings () {
            return dock_settings;
        }

        void load_dock_theme () {
            var new_theme = new Plank.DockTheme (dock_settings.Theme);
            new_theme.load ("dock");
            dock_theme_changed (dock_theme, new_theme);
            dock_theme = new_theme;
        }
    }
}
