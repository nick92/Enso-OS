//
//  Copyright (C) 2014 Tom Beckmann
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

namespace Gala
{
	delegate PluginInfo RegisterPluginFunction ();

	public class PluginManager : Object
	{
		static PluginManager? instance = null;
		public static unowned PluginManager get_default ()
		{
			if (instance == null)
				instance = new PluginManager ();

			return instance;
		}

		public signal void regions_changed ();

		public bool initialized { get; private set; default = false; }

		public X.Xrectangle[] regions { get; private set; }

		public string? window_switcher_provider { get; private set; default = null; }
		public string? desktop_provider { get; private set; default = null; }
		public string? window_overview_provider { get; private set; default = null; }
		public string? workspace_view_provider { get; private set; default = null; }

		HashTable<string,Plugin> plugins;
		File plugin_dir;

		WindowManager? wm = null;

		Gee.LinkedList<PluginInfo?> load_later_plugins;

		PluginManager ()
		{
			plugins = new HashTable<string,Plugin> (str_hash, str_equal);
			load_later_plugins = new Gee.LinkedList<PluginInfo?> ();

			if (!Module.supported ()) {
				warning ("Modules are not supported on this platform");
				return;
			}

			plugin_dir = File.new_for_path (Config.PLUGINDIR);
			if (!plugin_dir.query_exists ())
				return;

			try {
				var enumerator = plugin_dir.enumerate_children (FileAttribute.STANDARD_NAME +
					"," + FileAttribute.STANDARD_CONTENT_TYPE, 0);
				FileInfo info;
				while ((info = enumerator.next_file ()) != null) {
					if (info.get_content_type () == "application/x-sharedlib")
						load_module (info.get_name ());
				}
			} catch (Error e) {
				warning (e.message);
			}

			try {
				plugin_dir.monitor_directory (FileMonitorFlags.NONE, null).changed.connect ((file, other_file, type) => {
					if (type == FileMonitorEvent.CREATED) {
						load_module (file.get_basename ());
					}
				});
			} catch (Error e) {
				warning (e.message);
			}
		}

		bool load_module (string plugin_name)
		{
			var path = Module.build_path (plugin_dir.get_path (), plugin_name);
			var module = Module.open (path, ModuleFlags.BIND_LOCAL);
			if (module == null) {
				warning (Module.error ());
				return false;
			}

			void* function;
			module.symbol ("register_plugin", out function);
			if (function == null) {
				warning ("%s failed to register: register_plugin() function not found", plugin_name);
				return false;
			}
			unowned RegisterPluginFunction register = (RegisterPluginFunction)function;

			var info = register ();
			if (info.plugin_type.is_a (typeof (Plugin)) == false) {
				warning ("%s does not return a class of type Plugin", plugin_name);
				return false;
			}

			if (!check_provides (info.name, info.provides)) {
				return false;
			}

			info.module_name = plugin_name;
			module.make_resident ();

			if (info.load_priority == LoadPriority.DEFERRED && !initialized) {
				load_later_plugins.add (info);
			} else {
				load_plugin_class (info);
			}

			return true;
		}

		void load_plugin_class (PluginInfo info)
		{
			var plugin = (Plugin)Object.@new (info.plugin_type);
			plugins.set (info.module_name, plugin);

			debug ("Loaded plugin %s (%s)", info.name, info.module_name);

			if (initialized) {
				initialize_plugin (info.module_name, plugin);
				recalculate_regions ();
			}
		}

		void initialize_plugin (string plugin_name, Plugin plugin)
		{
			plugin.initialize (wm);
			plugin.region_changed.connect (recalculate_regions);
		}

		bool check_provides (string name, PluginFunction provides)
		{
			var message = "Plugins %s and %s both provide %s functionality, using first one only";
			switch (provides) {
				case PluginFunction.WORKSPACE_VIEW:
					if (workspace_view_provider != null) {
						warning (message, workspace_view_provider, name, "workspace view");
						return false;
					}
					workspace_view_provider = name;
					return true;
				case PluginFunction.WINDOW_OVERVIEW:
					if (window_overview_provider != null) {
						warning (message, window_overview_provider, name, "window overview");
						return false;
					}
					window_overview_provider = name;
					return true;
				case PluginFunction.DESKTOP:
					if (desktop_provider != null) {
						warning (message, desktop_provider, name, "desktop");
						return false;
					}
					desktop_provider = name;
					return true;
				case PluginFunction.WINDOW_SWITCHER:
					if (window_switcher_provider != null) {
						warning (message, window_switcher_provider, name, "window switcher");
						return false;
					}
					window_switcher_provider = name;
					return true;
			}

			return true;
		}

		public void initialize (WindowManager _wm)
		{
			wm = _wm;

			plugins.@foreach (initialize_plugin);
			recalculate_regions ();

			initialized = true;
		}

		public void load_waiting_plugins ()
		{
			foreach (var info in load_later_plugins) {
				load_plugin_class (info);
			}

			load_later_plugins.clear ();
		}

		public Plugin? get_plugin (string id)
		{
			return plugins.lookup (id);
		}

		/**
		 * Iterate over all plugins and grab their regions, update the regions
		 * array accordingly and emit the regions_changed signal.
		 */
		void recalculate_regions ()
		{
			X.Xrectangle[] regions = {};

			plugins.@foreach ((name, plugin) => {
				foreach (var region in plugin.region) {
					X.Xrectangle rect = {
						(short) region.x,
						(short) region.y,
						(ushort) region.width,
						(ushort) region.height
					};

					regions += rect;
				}
			});

			this.regions = regions;
			regions_changed ();
		}
	}
}

