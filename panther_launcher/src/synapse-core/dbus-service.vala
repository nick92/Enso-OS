/*
 * Copyright (C) 2010 Michal Hruby <michal.mhr@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by Michal Hruby <michal.mhr@gmail.com>
 *
 */

namespace Synapse
{
  [DBus (name = "org.freedesktop.DBus")]
  public interface FreeDesktopDBus : GLib.Object
  {
    public const string UNIQUE_NAME = "org.freedesktop.DBus";
    public const string OBJECT_PATH = "/org/freedesktop/DBus";

    public abstract async string[] list_queued_owners (string name) throws IOError;
    public abstract async string[] list_names () throws IOError;
    public abstract async string[] list_activatable_names () throws IOError;
    public abstract async bool name_has_owner (string name) throws IOError;
    public signal void name_owner_changed (string name,
                                           string old_owner,
                                           string new_owner);
    public abstract async uint32 start_service_by_name (string name,
                                               uint32 flags) throws IOError;
    public abstract async string get_name_owner (string name) throws IOError;
  }
  
  public class DBusService : Object
  {
    private FreeDesktopDBus proxy;
    private Gee.Set<string> owned_names;
    private Gee.Set<string> activatable_names;
    private Gee.Set<string> system_activatable_names;
    
    private Utils.AsyncOnce<bool> init_once;

    // singleton that can be easily destroyed
    public static DBusService get_default ()
    {
      return instance ?? new DBusService ();
    }

    private DBusService ()
    {
    }
    
    private static unowned DBusService? instance;
    construct
    {
      instance = this;
      owned_names = new Gee.HashSet<string> ();
      activatable_names = new Gee.HashSet<string> ();
      system_activatable_names = new Gee.HashSet<string> ();
      init_once = new Utils.AsyncOnce<bool> ();

      initialize.begin ();
    }
    
    ~DBusService ()
    {
      instance = null;
    }
    
    private void name_owner_changed (FreeDesktopDBus sender,
                                     string name,
                                     string old_owner,
                                     string new_owner)
    {
      if (name.has_prefix (":")) return;

      if (old_owner == "")
      {
        owned_names.add (name);
        owner_changed (name, true);
      }
      else if (new_owner == "")
      {
        owned_names.remove (name);
        owner_changed (name, false);
      }
    }
    
    public signal void owner_changed (string name, bool is_owned);
    
    public bool name_has_owner (string name)
    {
      return name in owned_names;
    }
    
    public bool name_is_activatable (string name)
    {
      return name in activatable_names;
    }
    
    public bool service_is_available (string name)
    {
      return name in system_activatable_names;
    }

    public async void initialize ()
    {
      if (init_once.is_initialized ()) return;
      var is_locked = yield init_once.enter ();
      if (!is_locked) return;

      string[] names;
      try
      {
        proxy = Bus.get_proxy_sync (BusType.SESSION,
                                    FreeDesktopDBus.UNIQUE_NAME,
                                    FreeDesktopDBus.OBJECT_PATH);

        proxy.name_owner_changed.connect (this.name_owner_changed);
        names = yield proxy.list_names ();
        foreach (unowned string name in names)
        {
          if (name.has_prefix (":")) continue;
          owned_names.add (name);
        }
        
        names = yield proxy.list_activatable_names ();
        foreach (unowned string session_act in names)
        {
          activatable_names.add (session_act);
        }
      }
      catch (Error err)
      {
        warning ("%s", err.message);
      }

      try
      {
        FreeDesktopDBus sys_proxy = Bus.get_proxy_sync (
                                            BusType.SYSTEM,
                                            FreeDesktopDBus.UNIQUE_NAME,
                                            FreeDesktopDBus.OBJECT_PATH);

        names = yield sys_proxy.list_activatable_names ();
        foreach (unowned string system_act in names)
        {
          system_activatable_names.add (system_act);
        }
      }
      catch (Error sys_err)
      {
        warning ("%s", sys_err.message);
      }
      init_once.leave (true);
    }
  }
}

