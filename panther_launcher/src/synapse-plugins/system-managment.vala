/*
 * Copyright (C) 2010 Michal Hruby <michal.mhr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.
 *
 * Authored by Michal Hruby <michal.mhr@gmail.com>
 *
 */

namespace Synapse
{
  [DBus (name = "org.freedesktop.UPower")]
  public interface UPowerObject : Object
  {
    public const string UNIQUE_NAME = "org.freedesktop.UPower";
    public const string OBJECT_PATH = "/org/freedesktop/UPower";

    public abstract async void hibernate () throws IOError;
    public abstract async void suspend () throws IOError;
    public abstract async bool hibernate_allowed () throws IOError;
    public abstract async bool suspend_allowed () throws IOError;

    public abstract async void about_to_sleep () throws IOError;
  }

  [DBus (name = "org.freedesktop.ConsoleKit.Manager")]
  public interface ConsoleKitObject : Object
  {
    public const string UNIQUE_NAME = "org.freedesktop.ConsoleKit";
    public const string OBJECT_PATH = "/org/freedesktop/ConsoleKit/Manager";

    public abstract void restart () throws IOError;
    public abstract void stop () throws IOError;
    public abstract async bool can_restart () throws IOError;
    public abstract async bool can_stop () throws IOError;
  }

  [DBus (name = "org.freedesktop.login1.Manager")]
  public interface SystemdObject : Object
  {
    public const string UNIQUE_NAME = "org.freedesktop.login1";
    public const string OBJECT_PATH = "/org/freedesktop/login1";

    public abstract void reboot (bool interactive) throws IOError;
    public abstract void suspend (bool interactive) throws IOError;
    public abstract void hibernate (bool interactive) throws IOError;
    public abstract void power_off (bool interactive) throws IOError;
    public abstract string can_suspend () throws IOError;
    public abstract string can_hibernate () throws IOError;
    public abstract string can_reboot () throws IOError;
    public abstract string can_power_off () throws IOError;
  }

  public class SystemManagementPlugin : Object, Activatable, ItemProvider
  {
    public bool enabled { get; set; default = true; }

    public void activate ()
    {

    }

    public void deactivate ()
    {

    }

    private abstract class SystemAction : Object, Match
    {
      // for Match interface
      public string title { get; construct set; }
      public string description { get; set; default = ""; }
      public string icon_name { get; construct set; default = ""; }
      public bool has_thumbnail { get; construct set; default = false; }
      public string thumbnail_path { get; construct set; }
      public MatchType match_type { get; construct set; }

      public abstract void do_action ();

      public abstract bool action_allowed ();

      public void execute (Match? match) {
        do_action ();
      }
    }

    private class SuspendAction : SystemAction
    {
      public SuspendAction ()
      {
        Object (title: _("Suspend"), match_type: MatchType.ACTION,
                description: _("Put your computer into suspend mode"),
                icon_name: "system-suspend", has_thumbnail: false);
      }

      construct
      {
        check_allowed.begin ();
      }

      private async void check_allowed ()
      {
        try
        {
          SystemdObject dbus_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                                           SystemdObject.UNIQUE_NAME,
                                           SystemdObject.OBJECT_PATH);

          allowed = (dbus_interface.can_suspend () == "yes");
          return;
        }
        catch (IOError err)
        {
          warning ("%s", err.message);
          allowed = false;
        }

        try
        {
          UPowerObject dbus_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                                           UPowerObject.UNIQUE_NAME,
                                           UPowerObject.OBJECT_PATH);

          allowed = yield dbus_interface.suspend_allowed ();
        }
        catch (IOError err)
        {
          warning ("%s", err.message);
          allowed = false;
        }
      }

      private bool allowed = false;

      public override bool action_allowed ()
      {
        return allowed;
      }

      private async void do_suspend ()
      {
        try
        {
          SystemdObject dbus_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                                           SystemdObject.UNIQUE_NAME,
                                           SystemdObject.OBJECT_PATH);

          dbus_interface.suspend (true);
          return;
        }
        catch (IOError err)
        {
          warning ("%s", err.message);
        }

        try
        {
          UPowerObject dbus_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                                           UPowerObject.UNIQUE_NAME,
                                           UPowerObject.OBJECT_PATH);

          try
          {
            yield dbus_interface.about_to_sleep ();
          }
          catch (Error not_there_error) { }
          // yea kinda nasty
          //GnomeScreenSaverPlugin.lock_screen ();
          // wait 2 seconds
          Timeout.add (2000, do_suspend.callback);
          yield;

          yield dbus_interface.suspend ();
        }
        catch (IOError err)
        {
          warning ("%s", err.message);
        }
      }

      public override void do_action ()
      {
        do_suspend.begin ();
      }
    }

    private class HibernateAction : SystemAction
    {
      public HibernateAction ()
      {
        Object (title: _("Hibernate"), match_type: MatchType.ACTION,
                description: _("Put your computer into hibernation mode"),
                icon_name: "system-hibernate", has_thumbnail: false);
      }

      construct
      {
        check_allowed.begin ();
      }

      private async void check_allowed ()
      {
        try
        {
          SystemdObject dbus_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                                           SystemdObject.UNIQUE_NAME,
                                           SystemdObject.OBJECT_PATH);

          allowed = (dbus_interface.can_hibernate () == "yes");
          return;
        }
        catch (IOError err)
        {
          warning ("%s", err.message);
          allowed = false;
        }

        try
        {
          UPowerObject dbus_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                                           UPowerObject.UNIQUE_NAME,
                                           UPowerObject.OBJECT_PATH);

          allowed = yield dbus_interface.hibernate_allowed ();
        }
        catch (IOError err)
        {
          warning ("%s", err.message);
          allowed = false;
        }
      }

      private bool allowed = false;

      public override bool action_allowed ()
      {
        return allowed;
      }

      private async void do_hibernate ()
      {
        try
        {
          SystemdObject dbus_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                                           SystemdObject.UNIQUE_NAME,
                                           SystemdObject.OBJECT_PATH);

          dbus_interface.hibernate (true);
          return;
        }
        catch (IOError err)
        {
          warning ("%s", err.message);
        }

        try
        {
          UPowerObject dbus_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                                           UPowerObject.UNIQUE_NAME,
                                           UPowerObject.OBJECT_PATH);

          try
          {
            yield dbus_interface.about_to_sleep ();
          }
          catch (Error not_there_error) { }
          // yea kinda nasty
          //GnomeScreenSaverPlugin.lock_screen ();
          // wait 2 seconds
          Timeout.add (2000, do_hibernate.callback);
          yield;
          dbus_interface.hibernate.begin ();
        }
        catch (IOError err)
        {
          warning ("%s", err.message);
        }
      }

      public override void do_action ()
      {
        do_hibernate.begin ();
      }
    }

    private class ShutdownAction : SystemAction
    {
      public ShutdownAction ()
      {
        Object (title: _("Shut Down"), match_type: MatchType.ACTION,
                description: _("Turn your computer off"),
                icon_name: "system-shutdown", has_thumbnail: false);
      }

      construct
      {
        check_allowed.begin ();
      }

      private async void check_allowed ()
      {
        try
        {
          SystemdObject dbus_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                                           SystemdObject.UNIQUE_NAME,
                                           SystemdObject.OBJECT_PATH);

          allowed = (dbus_interface.can_power_off () == "yes");
          return;
        }
        catch (IOError err)
        {
          warning ("%s", err.message);
          allowed = false;
        }

        try
        {
          ConsoleKitObject dbus_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                                           ConsoleKitObject.UNIQUE_NAME,
                                           ConsoleKitObject.OBJECT_PATH);

          allowed = yield dbus_interface.can_stop ();
        }
        catch (IOError err)
        {
          warning ("%s", err.message);
          allowed = false;
        }
      }

      private bool allowed = false;

      public override bool action_allowed ()
      {
        return allowed;
      }

      public override void do_action ()
      {
        try
        {
          SystemdObject dbus_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                                           SystemdObject.UNIQUE_NAME,
                                           SystemdObject.OBJECT_PATH);

          dbus_interface.power_off (true);
          return;
        }
        catch (IOError err)
        {
          warning ("%s", err.message);
        }

        try
        {
          ConsoleKitObject dbus_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                                           ConsoleKitObject.UNIQUE_NAME,
                                           ConsoleKitObject.OBJECT_PATH);

          dbus_interface.stop ();
        }
        catch (IOError err)
        {
          warning ("%s", err.message);
        }
      }
    }

    private class RestartAction : SystemAction
    {
      public RestartAction ()
      {
        Object (title: _("Restart"), match_type: MatchType.ACTION,
                description: _("Restart your computer"),
                icon_name: "system-restart", has_thumbnail: false);
      }

      construct
      {
        check_allowed.begin ();
      }

      private async void check_allowed ()
      {
        try
        {
          SystemdObject dbus_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                                           SystemdObject.UNIQUE_NAME,
                                           SystemdObject.OBJECT_PATH);

          allowed = (dbus_interface.can_reboot () == "yes");
          return;
        }
        catch (IOError err)
        {
          warning ("%s", err.message);
          allowed = false;
        }

        try
        {
          ConsoleKitObject dbus_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                                           ConsoleKitObject.UNIQUE_NAME,
                                           ConsoleKitObject.OBJECT_PATH);

          allowed = yield dbus_interface.can_restart ();
        }
        catch (IOError err)
        {
          warning ("%s", err.message);
          allowed = false;
        }
      }

      private bool allowed = false;

      public override bool action_allowed ()
      {
        return allowed;
      }

      public override void do_action ()
      {
        try
        {
          SystemdObject dbus_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                                           SystemdObject.UNIQUE_NAME,
                                           SystemdObject.OBJECT_PATH);

          dbus_interface.reboot (true);
          return;
        }
        catch (IOError err)
        {
          warning ("%s", err.message);
        }

        try
        {
          ConsoleKitObject dbus_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                                           ConsoleKitObject.UNIQUE_NAME,
                                           ConsoleKitObject.OBJECT_PATH);

          dbus_interface.restart ();
        }
        catch (IOError err)
        {
          warning ("%s", err.message);
        }
      }
    }

    static void register_plugin ()
    {
      DataSink.PluginRegistry.get_default ().register_plugin (
        typeof (SystemManagementPlugin),
        "System Management",
        _("Suspend, hibernate, restart or shutdown your computer."),
        "system-restart",
        register_plugin,
        DBusService.get_default ().service_is_available (SystemdObject.UNIQUE_NAME) ||
        DBusService.get_default ().service_is_available (ConsoleKitObject.UNIQUE_NAME),
        _("ConsoleKit wasn't found")
      );
    }

    static construct
    {
      register_plugin ();
    }

    private Gee.List<SystemAction> actions;

    construct
    {
      actions = new Gee.LinkedList<SystemAction> ();
      actions.add (new SuspendAction ());
      actions.add (new HibernateAction ());
      actions.add (new ShutdownAction ());
      actions.add (new RestartAction ());
    }

    public async ResultSet? search (Query q) throws SearchError
    {
      // we only search for actions
      if (!(QueryFlags.ACTIONS in q.query_type)) return null;

      var result = new ResultSet ();

      var matchers = Query.get_matchers_for_query (q.query_string, 0,
        RegexCompileFlags.OPTIMIZE | RegexCompileFlags.CASELESS);

      foreach (var action in actions)
      {
        if (!action.action_allowed ()) continue;
        foreach (var matcher in matchers)
        {
          if (matcher.key.match (action.title))
          {
            result.add (action, matcher.value - Match.Score.INCREMENT_SMALL);
            break;
          }
        }
      }

      q.check_cancellable ();

      return result;
    }
  }
}