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

#if HAVE_ZEITGEIST
using Zeitgeist;
//using GLib.Math

namespace Synapse
{
  private class ZeitgeistRelevancyBackend: Object, RelevancyBackend
  {
    private Zeitgeist.Log zg_log;
    private Zeitgeist.DataSourceRegistry zg_dsr;
    private Gee.Map<string, int> application_popularity;
    private Gee.Map<string, int> uri_popularity;
    private bool has_datahub_gio_module = false;

    private const float MULTIPLIER = 65535.0f;

    construct
    {
      zg_log = new Zeitgeist.Log ();
      application_popularity = new Gee.HashMap<string, int> ();
      uri_popularity = new Gee.HashMap<string, int> ();

      refresh_popularity ();
      check_data_sources.begin ();

      Timeout.add_seconds (60*30, refresh_popularity);
    }

    private async void check_data_sources ()
    {
      zg_dsr = new Zeitgeist.DataSourceRegistry ();
      try
      {
        var array = yield zg_dsr.get_data_sources (null);

        array.foreach ((ds) => {
          if (ds.unique_id == "com.zeitgeist-project,datahub,gio-launch-listener"
              && ds.enabled)
          {
            has_datahub_gio_module = true;
            return;
          }
        });
      }
      catch (Error err)
      {
        warning ("Unable to check Zeitgeist data sources: %s", err.message);
      }
    }

    private bool refresh_popularity ()
    {
      load_application_relevancies.begin ();
      load_uri_relevancies.begin ();
      return true;
    }

    private async void load_application_relevancies ()
    {
      Idle.add (load_application_relevancies.callback, Priority.LOW);
      yield;

      int64 end = new DateTime.now_local ().to_unix () * 1000;
      int64 start = end - Zeitgeist.Timestamp.WEEK * 4;
      Zeitgeist.TimeRange tr = new Zeitgeist.TimeRange (start, end);

      var event = new Zeitgeist.Event ();
      event.interpretation = "!" + Zeitgeist.ZG.LEAVE_EVENT;
      var subject = new Zeitgeist.Subject ();
      subject.interpretation = Zeitgeist.NFO.SOFTWARE;
      subject.uri = "application://*";
      event.add_subject (subject);

      var array = new GenericArray<Zeitgeist.Event> ();
      array.add (event);

      Zeitgeist.ResultSet rs;

      try
      {
        rs = yield zg_log.find_events (tr, array,
                                       Zeitgeist.StorageState.ANY,
                                       256,
                                       Zeitgeist.ResultType.MOST_POPULAR_SUBJECTS,
                                       null);

        application_popularity.clear ();
        uint size = rs.size ();
        uint index = 0;

        // Zeitgeist (0.6) doesn't have any stats API, so let's approximate

        foreach (Zeitgeist.Event e in rs)
        {
          if (e.num_subjects () <= 0) continue;
          Zeitgeist.Subject s = e.subjects[0];

          float power = index / (size * 2) + 0.5f; // linearly <0.5, 1.0>
          float relevancy = 1.0f / Math.powf (index + 1, power);
          application_popularity[s.uri] = (int)(relevancy * MULTIPLIER);

          index++;
        }
      }
      catch (Error err)
      {
        warning ("%s", err.message);
        return;
      }
    }

    private async void load_uri_relevancies ()
    {
      Idle.add (load_uri_relevancies.callback, Priority.LOW);
      yield;

      int64 end = new DateTime.now_local ().to_unix () * 1000;
      int64 start = end - Zeitgeist.Timestamp.WEEK * 4;
      Zeitgeist.TimeRange tr = new Zeitgeist.TimeRange (start, end);

      var event = new Zeitgeist.Event ();
      event.interpretation = "!" + Zeitgeist.ZG.LEAVE_EVENT;
      var subject = new Zeitgeist.Subject ();
      subject.interpretation = "!" + Zeitgeist.NFO.SOFTWARE;
      subject.uri = "file://*";
      event.add_subject (subject);

      var array = new GenericArray<Zeitgeist.Event> ();
      array.add (event);

      Zeitgeist.ResultSet rs;
      Gee.Map<string, int> popularity_map = new Gee.HashMap<string, int> ();

      try
      {
        uint size, index;
        float power, relevancy;
        /* Get popularity for file uris */
        rs = yield zg_log.find_events (tr, array,
                                       Zeitgeist.StorageState.ANY,
                                       256,
                                       Zeitgeist.ResultType.MOST_POPULAR_SUBJECTS,
                                       null);

        size = rs.size ();
        index = 0;

        // Zeitgeist (0.6) doesn't have any stats API, so let's approximate

        foreach (Zeitgeist.Event e1 in rs)
        {
          if (e1.num_subjects () <= 0) continue;
          Zeitgeist.Subject s1 = e1.subjects[0];

          power = index / (size * 2) + 0.5f; // linearly <0.5, 1.0>
          relevancy = 1.0f / Math.powf (index + 1, power);
          popularity_map[s1.uri] = (int)(relevancy * MULTIPLIER);

          index++;
        }
        
        /* Get popularity for web uris */
        subject.interpretation = Zeitgeist.NFO.WEBSITE;
        subject.uri = "";
        array = new GenericArray<Zeitgeist.Event> ();
        array.add (event);

        rs = yield zg_log.find_events (tr, array,
                                       Zeitgeist.StorageState.ANY,
                                       128,
                                       Zeitgeist.ResultType.MOST_POPULAR_SUBJECTS,
                                       null);

        size = rs.size ();
        index = 0;

        // Zeitgeist (0.6) doesn't have any stats API, so let's approximate

        foreach (Zeitgeist.Event e2 in rs)
        {
          if (e2.num_subjects () <= 0) continue;
          Zeitgeist.Subject s2 = e2.subjects[0];

          power = index / (size * 2) + 0.5f; // linearly <0.5, 1.0>
          relevancy = 1.0f / Math.powf (index + 1, power);
          popularity_map[s2.uri] = (int)(relevancy * MULTIPLIER);

          index++;
        }
      }
      catch (Error err)
      {
        warning ("%s", err.message);
      }

      uri_popularity = popularity_map;
    }
    
    public float get_application_popularity (string desktop_id)
    {
      if (application_popularity.has_key (desktop_id))
      {
        return application_popularity[desktop_id] / MULTIPLIER;
      }

      return 0.0f;
    }
    
    public float get_uri_popularity (string uri)
    {
      if (uri_popularity.has_key (uri))
      {
        return uri_popularity[uri] / MULTIPLIER;
      }

      return 0.0f;
    }
    
    private void reload_relevancies ()
    {
      Idle.add_full (Priority.LOW, () =>
      {
        load_application_relevancies.begin ();
        return false;
      });
    }
    
    public void application_launched (AppInfo app_info)
    {
      // FIXME: get rid of this maverick-specific workaround
      // detect if the Zeitgeist GIO module is installed
      Type zg_gio_module = Type.from_name ("GAppLaunchHandlerZeitgeist");
      // FIXME: perhaps we should check app_info.should_show?
      //   but user specifically asked to open this, so probably not
      //   otoh the gio module won't pick it up if it's not should_show
      if (zg_gio_module != 0)
      {
        Utils.Logger.debug (this, "libzg-gio-module detected, not pushing");
        reload_relevancies ();
        return;
      }

      if (has_datahub_gio_module)
      {
        reload_relevancies ();
        return;
      }

      string app_uri = null;
      if (app_info.get_id () != null)
      {
        app_uri = "application://" + app_info.get_id ();
      }
      else if (app_info is DesktopAppInfo)
      {
        string? filename = (app_info as DesktopAppInfo).get_filename ();
        if (filename == null) return;
        app_uri = "application://" + Path.get_basename (filename);
      }

      Utils.Logger.debug (this, "launched \"%s\", pushing to ZG", app_uri);
      push_app_launch (app_uri, app_info.get_display_name ());

      // and refresh
      reload_relevancies ();
    }

    private void push_app_launch (string app_uri, string? display_name)
    {
      //debug ("pushing launch event: %s [%s]", app_uri, display_name);
      var event = new Zeitgeist.Event ();
      var subject = new Zeitgeist.Subject ();

      event.actor = "application://synapse.desktop";
      event.interpretation = Zeitgeist.ZG.ACCESS_EVENT;
      event.manifestation = Zeitgeist.ZG.USER_ACTIVITY;
      event.add_subject (subject);

      subject.uri = app_uri;
      subject.interpretation = Zeitgeist.NFO.SOFTWARE;
      subject.manifestation = Zeitgeist.NFO.SOFTWARE_ITEM;
      subject.mimetype ="application/x-desktop";
      subject.text = display_name;

      try
      {
        zg_log.insert_event_no_reply (event);
      }
      catch (Error err)
      {
        warning ("%s", err.message);
        return;
      }
    }
  }
}
#endif
