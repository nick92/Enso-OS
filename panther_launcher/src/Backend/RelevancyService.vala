// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//
//  Copyright (C) 2011-2012 Panther Developers
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
//  Thanks to Synapse Developers for this class

#if HAVE_ZEITGEIST
public class Panther.Backend.RelevancyService : Object {

    private Zeitgeist.Log zg_log;
    private Zeitgeist.DataSourceRegistry zg_dsr;
    private Gee.HashMap<string, int> app_popularity;
    private bool has_datahub_gio_module = false;
    private bool refreshing = false;

    private const float MULTIPLIER = 65535.0f;
    
    public signal void update_complete ();

    public RelevancyService () {

        zg_log = new Zeitgeist.Log ();
        app_popularity = new Gee.HashMap<string, int> ();

        refresh_popularity ();
        check_data_sources.begin ();

        Timeout.add_seconds (60*30, refresh_popularity);

    }

    private async void check_data_sources () {

        zg_dsr = new Zeitgeist.DataSourceRegistry ();
        try {
            var ptr_arr = yield zg_dsr.get_data_sources (null);

            for (uint i=0; i < ptr_arr.length; i++) {

                unowned Zeitgeist.DataSource ds;
                ds = (Zeitgeist.DataSource) ptr_arr.get (i);
                if (ds.unique_id  == "com.zeitgeist-project,datahub,gio-launch-listener"
                        && ds.enabled == true) {

                    has_datahub_gio_module = true;
                    break;
                }
            }
        } catch (Error e) {
            critical (e.message);
        }
    }

    public bool refresh_popularity () {

        load_application_relevancies.begin ();
        return true;

    }
    private void reload_relevancies () {

        Idle.add_full (Priority.LOW, () => {
            load_application_relevancies.begin ();
            return false;
        });
    }

    private async void load_application_relevancies () {

        Idle.add (load_application_relevancies.callback, Priority.HIGH);
        yield;

        /* 
         * Dont reload everything if a refresh is already running.
         * This avoids a double free exception in libzeitgeist-2.0.
         */
        if (refreshing == true)
            return;

        refreshing = true;
        int64 end = Zeitgeist.Timestamp.from_now ();
        int64 start = end - Zeitgeist.Timestamp.WEEK * 4;
        Zeitgeist.TimeRange tr = new Zeitgeist.TimeRange (start, end);

        var event = new Zeitgeist.Event ();
        event.interpretation = "!" + Zeitgeist.ZG.LEAVE_EVENT;
        var subject = new Zeitgeist.Subject ();
        subject.interpretation = Zeitgeist.NFO.SOFTWARE;
        subject.uri = "application://*";
        event.add_subject (subject);

        var ptr_arr = new GLib.GenericArray<Zeitgeist.Event> ();
        ptr_arr.add (event);

        try {
            Zeitgeist.ResultSet rs = yield zg_log.find_events (tr, ptr_arr,
                    Zeitgeist.StorageState.ANY,
                    256,
                    Zeitgeist.ResultType.MOST_POPULAR_SUBJECTS,
                    null);

            app_popularity.clear ();
            uint size = rs.size ();
            uint index = 0;

            // Zeitgeist (0.6) doesn't have any stats API, so let's approximate

            foreach (Zeitgeist.Event e in rs) {

                if (e.num_subjects () <= 0) continue;
                Zeitgeist.Subject s = e.get_subject (0);

                float power = index / (size * 2) + 0.5f; // linearly <0.5, 1.0>
                float relevancy = 1.0f / Math.powf (index + 1, power);
                app_popularity[s.uri] = (int)(relevancy * MULTIPLIER);
                index++;
            }
            update_complete ();
            refreshing = false;
        } catch (Error err) {
            critical (err.message);
            refreshing = false;
            return;
        }
    }

    public float get_app_popularity (string desktop_id) {

        var id = "application://" + desktop_id;

        if (app_popularity.has_key(id)) {
            return app_popularity[id] / MULTIPLIER;
        }

        return 0.0f;
    }

    public void app_launched (App app) {

        string app_uri = null;
        if (app.desktop_id != null) {
            app_uri = "application://" + app.desktop_id;
        }

        push_app_launch (app_uri, app.name);

        // and refresh
        reload_relevancies ();
    }

    private void push_app_launch (string app_uri, string? display_name) {

        message ("Pushing launch event: %s [%s]", app_uri, display_name);
        var event = new Zeitgeist.Event ();
        var subject = new Zeitgeist.Subject ();

        event.actor = "application://synapse.desktop";
        event.interpretation = Zeitgeist.ZG.ACCESS_EVENT;
        event.manifestation = Zeitgeist.ZG.USER_ACTIVITY;
        event.add_subject (subject);

        subject.uri = app_uri;
        subject.interpretation = Zeitgeist.NFO.SOFTWARE;
        subject.manifestation = Zeitgeist.NFO.SOFTWARE_ITEM;
        subject.mimetype = "application/x-desktop";
        subject.text = display_name;
        var ptr_arr = new GLib.GenericArray<Zeitgeist.Event> ();
        ptr_arr.add (event);
        
        try {
            zg_log.insert_events_no_reply (ptr_arr);
        } catch (Error e) {
            critical (e.message);
        }
    }
}
#endif
