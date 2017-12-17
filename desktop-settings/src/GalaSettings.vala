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

/*
taken from gala code
*/

const string SCHEMA = "org.pantheon.desktop.gala";

public class BehaviorSettings : Granite.Services.Settings {
    public bool edge_tiling { get; set; }
    public string panel_main_menu_action { get; set; }
    public string toggle_recording_action { get; set; }

    public string hotcorner_custom_command { get; set; }

    static BehaviorSettings? instance = null;

    private BehaviorSettings () {
        base (SCHEMA+".behavior");
    }

    public static BehaviorSettings get_default () {
        if (instance == null) {
            instance = new BehaviorSettings ();
        }

        return instance;
    }
}

public class AppearanceSettings : Granite.Services.Settings {
    public string button_layout { get; set; }
    public string theme { get; set; }
    public bool attach_modal_dialogs { get; set; }
    public bool dim_parents { get; set; }

    static AppearanceSettings? instance = null;

    private AppearanceSettings () {
        base (SCHEMA+".appearance");
    }

    public static AppearanceSettings get_default () {
        if (instance == null) {
            instance = new AppearanceSettings ();
        }

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
        base (SCHEMA+".shadows");
    }

    public static ShadowSettings get_default () {
        if (instance == null) {
            instance = new ShadowSettings ();
        }

        return instance;
    }
}

public class AnimationSettings : Granite.Services.Settings {
    public bool enable_animations { get; set; }
    public int open_duration { get; set; }
    public int snap_duration { get; set; }
    public int minimize_duration { get; set; }
    public int close_duration { get; set; }
    public int workspace_switch_duration { get; set; }

    static AnimationSettings? instance = null;

    private AnimationSettings () {
        base (SCHEMA+".animations");
    }

    public static AnimationSettings get_default () {
        if (instance == null) {
            instance = new AnimationSettings ();
        }

        return instance;
    }
}
