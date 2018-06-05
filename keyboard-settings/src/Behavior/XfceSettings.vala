/*
* Copyright (c) 2018 Enso
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

namespace Pantheon.Keyboard.Behavior
{
  public class XfceSettings : Object {

    construct {
        try { Xfconf.init (); } catch (Xfconf.Error ex){return;}
    }

    public void set_config_string (string channel, string property, string value) {
      var xfchannel = new Xfconf.Channel (channel);

			if(xfchannel != null){
				if(xfchannel.get_string(property, "") != "")
					xfchannel.set_string (property, value);
				}
			}
  }
}
