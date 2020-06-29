//
//  Copyright 2019 elementary, Inc. (https://elementary.io)
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
    [CCode (has_type_id = false)]
    public enum AnimationDuration {
        // Duration of the open animation
        OPEN = 350,
        // Duration of the close animation
        CLOSE = 195,
        // Duration of the minimize animation
        MINIMIZE = 200,
        // Duration of the menu mapping animation
        MENU_MAP = 150,
        // Duration of the snap animation as used by maximize/unmaximize
        SNAP = 250,
        // Duration of the workspace switch animation
        WORKSPACE_SWITCH = 300,
    }
}
