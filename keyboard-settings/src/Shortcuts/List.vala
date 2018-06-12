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

namespace Pantheon.Keyboard.Shortcuts {
    struct Group {
        public string icon_name;
        public string label;
        public string[] actions;
        public Schema[] schemas;
        public string[] keys;
    }

    class List : GLib.Object {
        public Group[] groups;
        public Group windows_group;
        public Group workspaces_group;
        public Group screenshot_group;
        public Group launchers_group;
        public Group media_group;
        public Group a11y_group;
        public Group system_group;
        public Group custom_group;

        construct {
            windows_group = {};
            windows_group.icon_name = "preferences-system-windows";
            windows_group.label = _("Windows");
            add_action (ref windows_group, Schema.WM, _("Show Desktop"), "show-desktop");
            add_action (ref windows_group, Schema.WM, _("Lower"), "lower");
            add_action (ref windows_group, Schema.WM, _("Maximize"), "maximize");
            add_action (ref windows_group, Schema.WM, _("Unmaximize"), "unmaximize");
            add_action (ref windows_group, Schema.WM, _("Toggle Maximized"), "toggle-maximized");
            add_action (ref windows_group, Schema.WM, _("Minimize"), "minimize");
            add_action (ref windows_group, Schema.WM, _("Toggle Fullscreen"), "toggle-fullscreen");
            add_action (ref windows_group, Schema.WM, _("Toggle on all Workspaces"), "toggle-on-all-workspaces");
            add_action (ref windows_group, Schema.WM, _("Toggle always on Top"), "toggle-above");
            add_action (ref windows_group, Schema.WM, _("Cycle Windows"), "switch-windows");
            add_action (ref windows_group, Schema.WM, _("Cycle Windows backwards"), "switch-windows-backward");
            add_action (ref windows_group, Schema.MUTTER, _("Tile Left"), "toggle-tiled-left");
            add_action (ref windows_group, Schema.MUTTER, _("Tile Right"), "toggle-tiled-right");
            //add_action (ref windows_group, Schema.GALA, _("Window Overview"), "expose-windows");
            //add_action (ref windows_group, Schema.GALA, _("Show All Windows"), "expose-all-windows");
            //add_action (ref windows_group, Schema.GALA, _("Picture in Picture Mode"), "pip");

            workspaces_group = {};
            workspaces_group.icon_name = "workspace-switcher";
            workspaces_group.label = _("Workspaces");
            add_action (ref workspaces_group, Schema.GALA, _("Workspace View"), "show-workspace-view");
            add_action (ref workspaces_group, Schema.WM, _("Switch left"), "switch-to-workspace-left");
            add_action (ref workspaces_group, Schema.WM, _("Switch right"), "switch-to-workspace-right");
            add_action (ref workspaces_group, Schema.GALA, _("Switch to first"), "switch-to-workspace-first");
            add_action (ref workspaces_group, Schema.GALA, _("Switch to new"), "switch-to-workspace-last");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 1"), "switch-to-workspace-1");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 2"), "switch-to-workspace-2");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 3"), "switch-to-workspace-3");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 4"), "switch-to-workspace-4");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 5"), "switch-to-workspace-5");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 6"), "switch-to-workspace-6");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 7"), "switch-to-workspace-7");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 8"), "switch-to-workspace-8");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 9"), "switch-to-workspace-9");
            add_action (ref workspaces_group, Schema.GALA, _("Cycle workspaces"), "cycle-workspaces-next");
            add_action (ref workspaces_group, Schema.GALA, _("Cycle workspaces backwards"), "cycle-workspaces-previous");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 1"), "move-to-workspace-1");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 2"), "move-to-workspace-2");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 3"), "move-to-workspace-3");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 4"), "move-to-workspace-4");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 5"), "move-to-workspace-5");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 6"), "move-to-workspace-6");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 7"), "move-to-workspace-7");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 8"), "move-to-workspace-8");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 9"), "move-to-workspace-9");
            add_action (ref workspaces_group, Schema.WM, _("Move to left workspace"), "move-to-workspace-left");
            add_action (ref workspaces_group, Schema.WM, _("Move to right workspace"), "move-to-workspace-right");

            screenshot_group = {};
            screenshot_group.icon_name = "accessories-screenshot";
            screenshot_group.label = _("Screenshots");
            add_action (ref screenshot_group, Schema.MEDIA, _("Grab the whole screen"), "screenshot");
            add_action (ref screenshot_group, Schema.MEDIA, _("Copy the whole screen to clipboard"), "screenshot-clip");
            add_action (ref screenshot_group, Schema.MEDIA, _("Grab the current window"), "window-screenshot");
            add_action (ref screenshot_group, Schema.MEDIA, _("Copy the current window to clipboard"), "window-screenshot-clip");
            //add_action (ref screenshot_group, Schema.MEDIA, _("Select an area to grab"), "area-screenshot");
            //add_action (ref screenshot_group, Schema.MEDIA, _("Copy an area to clipboard"), "area-screenshot-clip");

            launchers_group = {};
            launchers_group.icon_name = "preferences-desktop-applications";
            launchers_group.label = _("Applications");
            add_action (ref launchers_group, Schema.MEDIA, _("Email"), "email");
            add_action (ref launchers_group, Schema.MEDIA, _("Home Folder"), "home");
            add_action (ref launchers_group, Schema.MEDIA, _("Music"), "media");
            add_action (ref launchers_group, Schema.MEDIA, _("Terminal"), "terminal");
            add_action (ref launchers_group, Schema.MEDIA, _("Internet Browser"), "www");

            media_group = {};
            media_group.icon_name = "applications-multimedia";
            media_group.label = _("Media");
            add_action (ref media_group, Schema.MEDIA, _("Volume Up"), "volume-up");
            add_action (ref media_group, Schema.MEDIA, _("Volume Down"), "volume-down");
            add_action (ref media_group, Schema.MEDIA, _("Mute"), "volume-mute");
            add_action (ref media_group, Schema.MEDIA, _("Play"), "play");
            add_action (ref media_group, Schema.MEDIA, _("Pause"), "pause");
            add_action (ref media_group, Schema.MEDIA, _("Stop"), "stop");
            add_action (ref media_group, Schema.MEDIA, _("Previous Track"), "previous");
            add_action (ref media_group, Schema.MEDIA, _("Next Track"), "next");
            add_action (ref media_group, Schema.MEDIA, _("Eject"), "eject");

            a11y_group = {};
            a11y_group.icon_name = "preferences-desktop-accessibility";
            a11y_group.label = _("Universal Access");
            //add_action (ref a11y_group, Schema.MEDIA, _("Decrease Text Size"), "decrease-text-size");
            //add_action (ref a11y_group, Schema.MEDIA, _("Increase Text Size"), "increase-text-size");
            add_action (ref a11y_group, Schema.GALA, _("Magnifier Zoom in"), "zoom-in");
            add_action (ref a11y_group, Schema.GALA, _("Magnifier Zoom out"), "zoom-out");
            add_action (ref a11y_group, Schema.MEDIA, _("Toggle On Screen Keyboard"), "on-screen-keyboard");
            //add_action (ref a11y_group, Schema.MEDIA, _("Toggle Screenreader"), "screenreader");
            //add_action (ref a11y_group, Schema.MEDIA, _("Toggle High Contrast"), "toggle-contrast");

            system_group = {};
            system_group.icon_name = "preferences-system";
            system_group.label = _("System");
            //add_action (ref system_group, Schema.WM, _("Applications Menu"), "panel-main-menu");
            add_action (ref system_group, Schema.MEDIA, _("Lock"), "screensaver");
            add_action (ref system_group, Schema.MEDIA, _("Log Out"), "logout");

            custom_group = {};
            custom_group.icon_name = "applications-other";
            custom_group.label = _("Custom");

            groups = {
                windows_group,
                workspaces_group,
                screenshot_group,
                launchers_group,
                media_group,
                a11y_group,
                system_group
            };
        }

        public void get_group (SectionID group, out string[] a, out Schema[] s, out string[] k) {
            a = groups[group].actions;
            s = groups[group].schemas;
            k = groups[group].keys;
            return;
        }

        public void add_action (ref Group group, Schema schema, string action, string key) {
            group.keys += key;
            group.schemas += schema;
            group.actions += action;
        }
    }
}
