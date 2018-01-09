/*
 * Copyright (c) 2011-2015 Wingpanel Developers (http://launchpad.net/wingpanel)
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
 * Boston, MA 02110-1301 USA.
 */

/*
 *   The method for calculating the background information and the classes that are
 *   related to it are copied from Gala.DBus.
 */

 public struct ColorInformation {
     double average_red;
     double average_green;
     double average_blue;
     double mean_luminance;
     double luminance_variance;
 }

 [DBus (name = "org.pantheon.gala")]
 interface Gala : Object {
     public signal void BackgroundChanged ();
     public abstract ColorInformation GetBackgroundColorInformation(int screen, int ref_x, int ref_y, int width, int height) throws IOError;
     public abstract void PerformAction(int action) throws IOError;
 }

namespace Plank {

    public class GalaDBus : GLib.Object
    {
        static GalaDBus? instance;
        Gala gala;
        ColorInformation color_information;

        public double gala_mean_luminance { get; set; }

        public signal void bg_changed();

		/**
		 * Get the singleton instance of {@link Plank.DBusClient}
		 */
		public static unowned GalaDBus get_instance ()
		{
			if (instance == null)
				instance = new GalaDBus ();

			return instance;
		}

        GalaDBus () {
            Object ();
        }

        void on_background_changed () {
            color_information = gala.GetBackgroundColorInformation (0, 0, 0, 1000, 500);
            this.gala_mean_luminance = color_information.mean_luminance;
            bg_changed();
        }

        construct {
            try {

                gala = Bus.get_proxy_sync (BusType.SESSION,
                                                  "org.pantheon.gala", "/org/pantheon/gala");
                gala.BackgroundChanged.connect (on_background_changed);
            } catch (IOError e) {
                warning ("%s\n", e.message);
            }
        }
    }
}
