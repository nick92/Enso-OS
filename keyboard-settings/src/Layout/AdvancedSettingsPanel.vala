/*
* Copyright (c) 2017 elementary, LLC. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/
    
public class AdvancedSettingsPanel : Gtk.Grid {
    public string name;
    public string [] input_sources;
    public string [] exclusions;
    public AdvancedSettingsPanel (string name, string [] input_sources, string [] exclusions = {}) {
        this.name = name;
        this.input_sources = input_sources;
        this.exclusions = exclusions;

        this.row_spacing = 12;
        this.column_spacing = 12;
        this.margin_top = 0;
        this.margin_bottom  = 12;
        this.column_homogeneous = false;
        this.row_homogeneous = false;

        this.hexpand = true;
        this.halign = Gtk.Align.CENTER;
    }
}
