/***
Copyright (C) 2014-2015 Marvin Beckers
Copyright (C) 2014-2015 Tom Beckmann
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

[CCode (cheader_filename = "run-passwd.h")]
namespace Passwd {
	public delegate void PasswdCallback (Handler handler, GLib.Error? e);

	[Compact, CCode (cname = " PasswdHandler", lower_case_cprefix = "passwd_", free_function = "passwd_destroy")]
	public class Handler {
		[CCode (cname = "passwd_init")]
		public Handler ();
	}

	[CCode (cname = "passwd_authenticate")]
	public void passwd_authenticate (Handler handler, string cur_pw, PasswdCallback cb);

	[CCode (cname = "passwd_destroy")]
	public void passwd_destroy (Handler handler);

	[CCode (cname = "passwd_change_password")]
	public bool passwd_change_password (Handler handler, string new_pw, PasswdCallback cb);
}
