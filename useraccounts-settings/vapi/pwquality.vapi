/* libpwquality Vala Bindings
 * Copyright 2013 Evan Nemerson <evan@coeus-group.com>
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

[CCode (lower_case_cprefix = "pwquality_", cheader_filename = "pwquality.h")]
namespace PasswordQuality {
	[CCode (cname = "int", cprefix = "PWQ_SETTING_", has_type_id = false)]
	public enum Setting {
		DIFF_OK,
		MIN_LENGTH,
		DIG_CREDIT,
		UP_CREDIT,
		LOW_CREDIT,
		OTH_CREDIT,
		MIN_CLASS,
		MAX_REPEAT,
		DICT_PATH,
		MAX_CLASS_REPEAT,
		GECOS_CHECK,
		BAD_WORDS,
		MAX_SEQUENCE
	}

	[CCode (cname = "int", cprefix = "PWQ_ERROR_", has_type_id = false)]
	public enum Error {
		SUCCESS,
		FATAL_FAILURE,
		INTEGER,
		CFGFILE_OPEN,
		CFGFILE_MALFORMED,
		UNKNOWN_SETTING,
		NON_INT_SETTING,
		NON_STR_SETTING,
		MEM_ALLOC,
		TOO_SIMILAR,
		MIN_DIGITS,
		MIN_UPPERS,
		MIN_LOWERS,
		MIN_OTHERS,
		MIN_LENGTH,
		PALINDROME,
		CASE_CHANGES_ONLY,
		ROTATED,
		MIN_CLASSES,
		MAX_CONSECUTIVE,
		EMPTY_PASSWORD,
		SAME_PASSWORD,
		CRACKLIB_CHECK,
		RNG,
		GENERATION_FAILED,
		USER_CHECK,
		GECOS_CHECK,
		MAX_CLASS_REPEAT,
		BAD_WORDS,
		MAX_SEQUENCE;

		[CCode (cname = "pwquality_strerror", instance_pos = 2.5)]
		private void* strerror (void* buf, size_t len, void* auxerror);

		public string to_string (void* auxerror = null) {
			string ret = null;
			string** retp = &ret;
			*retp = GLib.malloc (PasswordQuality.MAX_ERROR_MESSAGE_LEN);
			void* res = this.strerror (*retp, PasswordQuality.MAX_ERROR_MESSAGE_LEN, auxerror);

			if ( res != *retp ) {
				GLib.Memory.copy (*retp, res, ((string) res).length + 1);
			}

			return ret;
		}
	}

	[CCode (cname = "PWQ_MAX_ENTROPY_BITS")]
	public const int MAX_ENTROPY_BITS;
	[CCode (cname = "PWQ_MIN_ENTROPY_BITS")]
	public const int MIN_ENTROPY_BITS;
	[CCode (cname = "PWQ_MAX_ERROR_MESSAGE_LEN")]
	public const int MAX_ERROR_MESSAGE_LEN;

	[Compact, CCode (cname = "pwquality_settings_t", lower_case_cprefix = "pwquality_", free_function = "pwquality_free_settings")]
	public class Settings {
		[CCode (cname = "pwquality_default_settings")]
		public Settings ();

		public PasswordQuality.Error read_config (string cfgfile, out void* auxerror);
		public PasswordQuality.Error set_option (string option);
		public PasswordQuality.Error set_int_value (PasswordQuality.Setting setting, int value);
		public PasswordQuality.Error set_str_value (PasswordQuality.Setting setting, string value);
		public PasswordQuality.Error get_int_value (PasswordQuality.Setting setting, out int value);
		public PasswordQuality.Error get_str_value (PasswordQuality.Setting setting, out unowned string value);

		public PasswordQuality.Error generate (int entropy_bits, out string password);
		public int check (string password, string? oldpassword = null, string? user = null, out void* auxerror = null);
	}
}

