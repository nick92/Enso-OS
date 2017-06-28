// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//
//  Copyright (C) 2011-2012 Giulio Collura
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

using Posix;

namespace Panther {

    public class Settings : Object {


        public int columns;
        public int rows;
        public int columns_int { get; set; }
        public int rows_int { get; set; }
        public double font_size { get; set; }

        public int icon_size { get; set; }
        public bool show_category_filter { get; set; }
        public bool use_category { get; set; }
        public string screen_resolution { get; set; }
        public string resolution { get; set; }
        public bool show_at_top {get; set; }

        private GLib.Settings panther_settings;

        public signal void columns_changed();
        public signal void rows_changed();
        public signal void show_at_changed();

        public Settings () {
            this.panther_settings = new GLib.Settings("org.rastersoft.panther");
            this.panther_settings.bind("rows",this,"rows_int",SettingsBindFlags.DEFAULT);
            this.panther_settings.bind("columns",this,"columns_int",SettingsBindFlags.DEFAULT);
            this.panther_settings.bind("icon-size",this,"icon_size",SettingsBindFlags.DEFAULT);
            this.panther_settings.bind("font-size",this,"font_size",SettingsBindFlags.DEFAULT);
            this.panther_settings.bind("show-category-filter",this,"show_category_filter",SettingsBindFlags.DEFAULT);
            this.panther_settings.bind("use-category",this,"use_category",SettingsBindFlags.DEFAULT);
            this.panther_settings.bind("screen-resolution",this,"screen_resolution",SettingsBindFlags.DEFAULT);
            this.panther_settings.bind("show-at-top",this,"show_at_top",SettingsBindFlags.DEFAULT);
            //this.panther_settings.bind("favourite",this,"favourite",SettingsBindFlags.DEFAULT);

            this.panther_settings.changed.connect((key) => {
                if (key == "rows") {
                    this.rows = this.rows_int;
                    this.rows_changed();
                }
                if (key == "columns") {
                    this.columns = this.columns_int;
                    this.columns_changed();
                }
                if (key == "show-at-top") {
                    this.show_at_changed();
                }
                if (key == "icon-size") {
                    Posix.exit(0);
                }
                if (key == "font-size") {
                    Posix.exit(0);
                }
            });
        }
    }
}
