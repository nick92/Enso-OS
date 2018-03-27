namespace Pantheon.Keyboard.Behaviour
{
	class SettingsRepeat : Granite.Services.Settings
	{
		public uint delay            { get; set; }
		public uint repeat_interval  { get; set; }

		public SettingsRepeat () { 
			base ("org.gnome.desktop.peripherals.keyboard");
		}
	}
	
	class SettingsBlink : Granite.Services.Settings
	{
		public int  cursor_blink_time    { get; set; }
		public int  cursor_blink_timeout { get; set; }

		public SettingsBlink () { 
			base ("org.gnome.desktop.interface");
		}
	}
}
