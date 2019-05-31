/***

    Copyright (C) 2019 Enso Developers

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as
    published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses>

***/

namespace Welcome {

	public class OptionsView : Gtk.EventBox {

		Gtk.Grid		grid;
		Gtk.FlowBox 	flow_box;
		FlowBoxItem 	install_apps;
		FlowBoxItem 	help;
		FlowBoxItem 	gitter;
		FlowBoxItem 	settings;
		FlowBoxItem 	user_details;

		construct {

			grid = new Gtk.Grid ();
			grid.orientation = Gtk.Orientation.VERTICAL;
			grid.expand = true;   // expand the box to fill the whole window
      grid.row_homogeneous = false;

			flow_box = new Gtk.FlowBox();
			flow_box.activate_on_single_click = true;
			flow_box.expand = true;
            flow_box.homogeneous = true;

        flow_box.child_activated.connect ((child) => {
				var item = child as FlowBoxItem;
				if(item != null) {
					spawn_process(item.s_title);
				}
			});

			install_apps = new FlowBoxItem ("Install Applications", "system-software-install");
			settings = new FlowBoxItem ("Change System Settings", "system-settings");
			user_details = new FlowBoxItem ("Edit User Details", "cs-user-accounts");
			help = new FlowBoxItem ("Learn Enso", "help-about");
			gitter = new FlowBoxItem ("Join the Conversation", "chat");

      flow_box.add(user_details);
			flow_box.add(settings);
			flow_box.add(install_apps);
			flow_box.add(help);
			flow_box.add(gitter);


			grid.add(flow_box);
			/*grid.add(settings);
			grid.add(install_apps);
			grid.add(help);
			grid.add(gitter);*/

			/*grid.attach(install_apps, 0, 0, 1, 1);
			//grid.attach(button_help, 1, 0, 1, 1);
			grid.attach(settings, 1, 0, 1, 1);
			grid.attach(user_details, 2, 0, 1, 1);
			grid.attach(help, 0, 1, 1, 1);
			grid.attach(gitter, 1, 1, 1, 1);*/

			add(grid);
		}
	}

	private void spawn_process (string title) {
		switch(title) {
			case "Install Applications":
				Process.spawn_command_line_async ("apphive");
				break;
			case "Change System Settings":
				Process.spawn_command_line_async ("xfce4-settings-manager");
				break;
			case "Edit User Details":
				Process.spawn_command_line_async ("mugshot");
				break;
			case "Learn Enso":
				Process.spawn_command_line_async ("firefox http://docs.enso-os.site/learn/");
				break;
			case "Join the Conversation":
				Process.spawn_command_line_async ("firefox https://gitter.im/Enso-OS/Lobby");
				break;
		}
	}
}
