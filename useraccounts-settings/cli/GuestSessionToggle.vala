/***
Copyright (C) 2015 Marvin Beckers
              2015 Rico Tzschichholz
This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License version 3, as published
by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranties of
MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see http://www.gnu.org/licenses/.
***/

namespace GuestSessionToggle {

	const string LIGHTDM_CONF = "/etc/lightdm/lightdm.conf";
	const string LIGHTDM_CONF_D = "/etc/lightdm/lightdm.conf.d";
	const string GUEST_SESSION_CONF = "/usr/share/lightdm/lightdm.conf.d/60-guest-session.conf";
	
	const OptionEntry[] options = {
		{ "show", 0, 0, OptionArg.NONE, ref SHOW, "Show whether guest-session is enabled", null },
		{ "show-autologin", 0, 0, OptionArg.NONE, ref SHOW_AUTOLOGIN, "Show whether guest will be logged in automatically", null },
		{ "on", 0, 0, OptionArg.NONE, ref ON, "Enable guest-session", null },
		{ "off", 0, 0, OptionArg.NONE, ref OFF, "Disable guest-session", null },
		{ "autologin-on", 0, 0, OptionArg.NONE, ref AUTOLOGIN_ON, "Enable guest autologin", null },
		{ "autologin-off", 0, 0, OptionArg.NONE, ref AUTOLOGIN_OFF, "Disable guest autologin", null },
		{ null }
	};

	static bool SHOW;
	static bool SHOW_AUTOLOGIN;
	static bool ON;
	static bool OFF;
	static bool AUTOLOGIN_ON;
	static bool AUTOLOGIN_OFF;

	public static int main (string[] args) {
		var context = new OptionContext (null);
		context.add_main_entries (options, null);
			
		try {
			context.parse (ref args);
		} catch (OptionError e) {
			printerr ("%s\n", e.message);
			return Posix.EXIT_FAILURE;
		}

		bool enabled;
		bool autologin_enabled;

		if (SHOW) {
			enabled = get_allow_guest ();
			
			if (enabled) 
				print ("on\n");
			else
				print ("off\n");

			return Posix.EXIT_SUCCESS;
		} else if (SHOW_AUTOLOGIN) {
			autologin_enabled = get_guest_autologin ();

			if (autologin_enabled) {
				print ("on\n");
			} else {
				print ("off\n");
			}

			return Posix.EXIT_SUCCESS;
		}
			
		var uid = Posix.getuid ();

		if (uid > 0) {
			printerr ("Must be run from administrative context\n");
			return Posix.EXIT_FAILURE;
		}

		enabled = get_allow_guest ();
		autologin_enabled = get_guest_autologin ();

		if (ON && !enabled)
			set_allow_guest (true);
		else if (OFF && enabled)
			set_allow_guest (false);
		else if (AUTOLOGIN_ON && !autologin_enabled)
			set_guest_autologin (true);
		else if (AUTOLOGIN_OFF && autologin_enabled)
			set_guest_autologin (false);

		return Posix.EXIT_SUCCESS;
	}

	private bool set_allow_guest (bool enable) {
		string @value = (enable ? "true" : "false");
		return set_setting ("SeatDefaults", "allow-guest", @value, GUEST_SESSION_CONF);
	}

	private bool get_allow_guest () {
		string @value = get_setting ("SeatDefaults", "allow-guest", "true").down ();
		return (@value == "true");
	}
	
	private bool get_guest_autologin () {
		string @value = get_setting ("SeatDefaults", "autologin-guest", "false").down ();
		return (@value == "true");
	}

	private bool set_guest_autologin (bool enable) {
		string @value = (enable ? "true" : "false");
		return set_setting ("SeatDefaults", "autologin-guest", @value, GUEST_SESSION_CONF);
	}

	private string get_setting (string group, string key, string default_value) {
		string? @value;

		// Source config-file accoring to their priority

		@value = get_config_from_file (LIGHTDM_CONF, group, key);
		if (@value != null)
			return @value;
		
		@value = get_config_from_directory (LIGHTDM_CONF_D, group, key);
		if (@value != null)
			return @value;

		@value = get_config_from_directories (Environment.get_system_config_dirs (), group, key);
		if (@value != null)
			return @value;
		
		@value = get_config_from_directories (Environment.get_system_data_dirs (), group, key);
		if (@value != null)
			return @value;

		printerr ("'[%s] %s' is not set anywhere assuming default '%s'\n", group, key, default_value);
		return default_value;
	}

	private string? get_config_from_directories (string[] dirs, string group, string key) {
		string? result = null;

		foreach (unowned string dir in dirs) {
			var full_dir = Path.build_filename (dir, "lightdm", "lightdm.conf.d");
			result = get_config_from_directory (full_dir, group, key);
			if (result != null)
				return result;
		}
		
		return null;
	}

	private string? get_config_from_directory (string path, string group, string key) {
		var files = new List<string> ();
		string? result = null;

		// Find files
		try {
			var dir = Dir.open (path);
			unowned string? name = null;
			while ((name = dir.read_name ()) != null)
				files.prepend (name);
		} catch (FileError e) {
			printerr ("Failed to open configuration directory %s: %s\n", path, e.message);
		}

		// Sort alphabetically
		files.sort (strcmp);

		foreach (unowned string filename in files) {
			var conf_path = Path.build_filename (path, filename);
			if (filename.has_suffix (".conf")) {
				result = get_config_from_file (conf_path, group, key);
				if (result != null)
					return result;
			} else {
				printerr ("Ignoring configuration file %s, it does not have .conf suffix", conf_path);
			}
		}
		
		return null;
	}

	private string? get_config_from_file (string path, string group, string key) {
		try {
			var key_file = new KeyFile ();
			key_file.load_from_file (path, KeyFileFlags.NONE);
			return key_file.get_string (group, key);
		} catch (KeyFileError e) {
		} catch (FileError e) {
			printerr ("Failed to open configuration file %s: %s\n", path, e.message);
		}
		
		return null;
	}

	private bool set_setting (string group, string key, string @value, string fallback_path) {
		// Source config-file accoring to their priority

		if (set_config_in_file (LIGHTDM_CONF, group, key, @value))
			return true;
		
		if (set_config_in_directory (LIGHTDM_CONF_D, group, key, @value))
			return true;

		if (set_config_in_directories (Environment.get_system_config_dirs (), group, key, @value))
			return true;
		
		if (set_config_in_directories (Environment.get_system_data_dirs (), group, key, @value))
			return true;

		printerr ("'[%s] %s' is not set anywhere, creating '%s'\n", group, key, fallback_path);
		return set_config_in_file (fallback_path, group, key, @value, true);
	}

	private bool set_config_in_directories (string[] dirs, string group, string key, string @value) {
		foreach (unowned string dir in dirs) {
			var full_dir = Path.build_filename (dir, "lightdm", "lightdm.conf.d");
			if (set_config_in_directory (full_dir, group, key, @value))
				return true;
		}
		
		return false;
	}

	private bool set_config_in_directory (string path, string group, string key, string @value) {
		var files = new List<string> ();

		// Find files
		try {
			var dir = Dir.open (path);
			unowned string? name = null;
			while ((name = dir.read_name ()) != null)
				files.prepend (name);
		} catch (FileError e) {
			printerr ("Failed to open configuration directory %s: %s\n", path, e.message);
		}

		// Sort alphabetically
		files.sort (strcmp);

		foreach (unowned string filename in files) {
			var conf_path = Path.build_filename (path, filename);
			if (filename.has_suffix (".conf")) {
				if (set_config_in_file (conf_path, group, key, @value))
					return true;
			} else {
				printerr ("Ignoring configuration file %s, it does not have .conf suffix", conf_path);
			}
		}
		
		return false;
	}

	private bool set_config_in_file (string path, string group, string key, string @value, bool create = false) {
		try {
			var key_file = new KeyFile ();
			if (FileUtils.test (path, FileTest.EXISTS))
				key_file.load_from_file (path, KeyFileFlags.KEEP_COMMENTS);
			else if (!create)
				return false;

			create = (create || key_file.has_key (group, key));
			if (create) {
				key_file.set_string (group, key, @value);
				key_file.save_to_file (path);
				return true;
			}			
		} catch (KeyFileError e) {
		} catch (FileError e) {
			printerr ("Failed to load/save configuration file %s: %s\n", path, e.message);
		}
		
		return false;
	}
}
