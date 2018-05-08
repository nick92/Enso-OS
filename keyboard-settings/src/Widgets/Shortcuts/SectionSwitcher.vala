/*
* Copyright (c) 2017-2018 elementary, LLC. (https://elementary.io)
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

class Pantheon.Keyboard.Shortcuts.SectionSwitcher : Gtk.ScrolledWindow {
    public signal bool changed (int i);

    private Gtk.ListBox listbox;

    construct {
        listbox = new Gtk.ListBox ();

        var frame = new Gtk.Frame (null);
        frame.add (listbox);

        add (frame);
        vexpand = true;

        listbox.row_selected.connect ((row) => {
            changed (row.get_index ());
        });
    }

    public void add_section (Pantheon.Keyboard.Shortcuts.Group group) {
        var icon = new Gtk.Image.from_icon_name (group.icon_name, Gtk.IconSize.DND);

        var label = new Gtk.Label (group.label);
        label.xalign = 0;

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.column_spacing = 6;
        grid.add (icon);
        grid.add (label);

        listbox.add (grid);
    }
}
