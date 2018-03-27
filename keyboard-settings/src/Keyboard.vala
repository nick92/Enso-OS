/***

    Copyright (C) 2017 Tranquil Developers

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as
    published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses>

***/

namespace Pantheon.Keyboard {

  public class Plug : Gtk.Application {
      Gtk.Stack stack;
      PlugWindow window = null;
      static Plug app;
      string display_name = "Keyboard";

      public Plug () {
          Object (application_id: "com.enso.plug.keyboard",
          flags: ApplicationFlags.FLAGS_NONE);

          var settings = new Gee.TreeMap<string, string?> (null, null);
          settings.set ("input/keyboard", "Layout");
          settings.set ("input/keyboard/layout", "Layout");
          settings.set ("input/keyboard/behavior", "Behavior");
          settings.set ("input/keyboard/shortcuts", "Shortcuts");
          /*Object (category: Category.HARDWARE,
                  code_name: "hardware-pantheon-keyboard",
                  display_name: _("Keyboard"),
                  description: _("Configure keyboard behavior, layouts, and shortcuts"),
                  icon: "preferences-desktop-keyboard",
                  supported_settings: settings);*/
      }

      protected override void activate () {
          if (window != null) {
              window.present ();
              return;
          }

          window = new PlugWindow ();
          window.set_application (this);
          window.delete_event.connect(window.main_quit);
          window.show_all ();

      }

      public static int main (string[] args) {
          Intl.setlocale (LocaleCategory.ALL, "");
          Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");
          Intl.textdomain (Build.GETTEXT_PACKAGE);

          app = new Plug ();

          if (args[1] == "-s") {
              return 0;
          }

          return app.run (args);
      }

      public void search_callback (string location) {
          switch (location) {
              default:
              case "Shortcuts":
                  stack.visible_child_name = "shortcuts";
                  break;
              case "Behavior":
                  stack.visible_child_name = "behavior";
                  break;
              case "Layout":
                  stack.visible_child_name = "layout";
                  break;
          }
      }

      // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
      public async Gee.TreeMap<string, string> search (string search) {
          var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
          search_results.set ("%s → %s".printf (display_name, _("Shortcuts")), "Shortcuts");
          search_results.set ("%s → %s".printf (display_name, _("Repeat Keys")), "Behavior");
          search_results.set ("%s → %s".printf (display_name, _("Cursor Blinking")), "Behavior");
          search_results.set ("%s → %s".printf (display_name, _("Switch layout")), "Layout");
          search_results.set ("%s → %s".printf (display_name, _("Compose Key")), "Layout");
          search_results.set ("%s → %s".printf (display_name, _("Caps Lock behavior")), "Layout");
          return search_results;
      }
  }

  /*public Switchboard.Plug get_plug (Module module) {
      debug ("Activating Keyboard plug");
      //var plug = new Pantheon.Keyboard.Plug ();
      return plug;
  }*/
}
