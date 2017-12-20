//
//  Copyright (C) 2015 Rico Tzschichholz
//
//  This file is part of Plank.
//
//  Plank is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Plank is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

using Plank;

namespace Docky
{
	public class BookmarksDockItem : DockletItem
	{
		private Gee.ArrayList<BookmarkItems> bookmarks = null;

		/**
		 * {@inheritDoc}
		 */
		public BookmarksDockItem.with_dockitem_file (GLib.File file)
		{
			GLib.Object (Prefs: new DockItemPreferences.with_file (file));
		}

		public signal void activate (string url);

		private static bool is_container (Json.Object o, string container_string)
	    {
	      return o.get_string_member ("type") == container_string;
	    }

	    private static bool is_bookmark (Json.Object o)
	    {
	      return o.has_member ("url");
	    }

	    private static bool is_good (Json.Object o, Gee.HashSet<string> unwanted_scheme)
	    {
	      return !unwanted_scheme.contains (o.get_string_member ("url")
	                                        .split (":", 1)[0]);
	    }

		
		construct
		{
		  Icon = "bookmarks";
		  Text = _("Web Bookmarks");

		  update ();
		}

		void update () {
			bookmarks = new Gee.ArrayList<BookmarkItems> ();
			var parser = new Json.Parser ();
			string fpath = GLib.Path.build_filename (
				Environment.get_user_config_dir (), "chromium", "Default", "Bookmarks");

			string CONTAINER = "folder";
			Gee.HashSet<string> UNWANTED_SCHEME = new Gee.HashSet<string> ();
			UNWANTED_SCHEME.add ("data");
			UNWANTED_SCHEME.add ("place");
			UNWANTED_SCHEME.add ("javascript");

			List<unowned Json.Node> folders = new List<Json.Node> ();

			try
			{
				File f = File.new_for_path (fpath);
				var input_stream = f.read ();
				parser.load_from_stream (input_stream);

				var root_object = parser.get_root ().get_object ();
				folders.concat (root_object.get_member ("roots").get_object ()
				                           .get_member ("bookmark_bar").get_object ()
				                           .get_array_member ("children").get_elements ());
				folders.concat (root_object.get_member ("roots").get_object ()
				                           .get_member ("other").get_object ()
				                           .get_array_member ("children").get_elements ());

				Json.Object o;
				foreach (var item in folders)
				{
				  o = item.get_object ();
				  if (is_bookmark (o) && is_good (o, UNWANTED_SCHEME))
				  {
				    bookmarks.add (new BookmarkItems(
				    	o.get_string_member ("name"), 
				    	o.get_string_member ("url")));
				  }
				  if (is_container (o, CONTAINER))
				  {
				    folders.concat(o.get_array_member ("children").get_elements ());
				  }
				}
			}
			catch (Error err)
			{
				warning ("%s", err.message);
			}
		}

		public override Gee.ArrayList<Gtk.MenuItem> get_menu_items ()
		{
			update ();

			var items = new Gee.ArrayList<Gtk.MenuItem> ();
			
			var item = create_menu_item ("Chromium");
			item.set_sensitive (false);
			items.add (item);		
			
			item = create_menu_item (_("New Tab"), "gtk-add");
			item.activate.connect(() => {
				open_bookmark("chrome://newtab/");
			});
			items.add (item);
			
			items.add (new Gtk.SeparatorMenuItem ());

			try {				
				foreach(BookmarkItems mark in bookmarks)
				{
					item = create_menu_item (mark.name);
					item.activate.connect(() => {
						open_bookmark(mark.url);
					});
					items.add (item);		
				}

			} catch (GLib.Error e) {
				warning ("Could not enumerate items in the trash.");
			}
			
			return items;
		}
		
		~BookmarksDockItem ()
		{
		  
		} 

		void open_bookmark (string url) {
	      if (!url.contains ("/embed/")) {
	          try {
        	  	//AppInfo.launch_default_for_uri (url, null);
          	  	//AppInfo.create_from_commandline("chromium-browser " + url, "chromium-browser", GLib.AppInfoCreateFlags.NONE);
  	  			Process.spawn_command_line_async ("chromium-browser " + url);
	          } catch (Error e) {
	              warning ("No app to handle urls: %s", e.message);
	          }
	      }
	    }
		
		protected override AnimationType on_clicked (PopupButton button, Gdk.ModifierType mod, uint32 event_time)
		{			
			return AnimationType.NONE;
		}
	}

	public class BookmarkItems {

		public string name { get; set; }
		public string url { get; set; }

		public BookmarkItems (string name, string url) {
			this.url = url;
			this.name = name;
		}
	}
}
