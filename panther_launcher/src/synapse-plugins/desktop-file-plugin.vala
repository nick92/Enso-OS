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
  public class DesktopFilePlugin: Object, Activatable, ItemProvider, ActionProvider
  {
    public bool enabled { get; set; default = true; }

    public void activate ()
    {
      
    }

    public void deactivate ()
    {
      
    }

    public class ActionMatch : Object, Match
    {
      public string title { get; construct set; }
      public string icon_name { get; construct set; default = ""; }
      public string description { get; set; default = ""; }
      public bool has_thumbnail { get; construct set; default = false; }
      public string thumbnail_path { get; construct set; }
      public MatchType match_type { get; construct set; }
      public string? filename { get; construct set; }

      public AppInfo? app_info { get; set; default = null; }
      public bool needs_terminal { get; set; default = false; }

      private string action_name;

      public ActionMatch (string desktop_id, string action_name)
      {
        var desktop_app_info = new DesktopAppInfo (desktop_id);
        this.title = desktop_app_info.get_action_name (action_name);
        this.icon_name = desktop_app_info.get_icon ().to_string ();
        this.description = "";
        this.app_info = desktop_app_info;
        this.action_name = action_name;
      }   

      public void execute (Match? match)
      {
        ((DesktopAppInfo) app_info).launch_action (action_name, new AppLaunchContext ());
      }       
    }

    private class DesktopFileMatch: Object, Match, ApplicationMatch
    {
      // for Match interface
      public string title { get; construct set; }
      public string description { get; set; default = ""; }
      public string icon_name { get; construct set; default = ""; }
      public bool has_thumbnail { get; construct set; default = false; }
      public string thumbnail_path { get; construct set; }
      public MatchType match_type { get; construct set; }

      // for ApplicationMatch
      public AppInfo? app_info { get; set; default = null; }
      public bool needs_terminal { get; set; default = false; }
      public string? filename { get; construct set; }

      // for additional matching
      public string generic_name { get; construct set; default = ""; }
      
      private string? title_folded = null;
      public unowned string get_title_folded ()
      {
        if (title_folded == null) title_folded = title.casefold ();
        return title_folded;
      }
      
      public string? title_unaccented { get; set; default = null; }
      public string? desktop_id { get; set; default = null; }

      public string exec { get; set; }

      public DesktopFileMatch.for_info (DesktopFileInfo info)
      {
        Object (filename: info.filename, match_type: MatchType.APPLICATION);

        init_from_info (info);
      }

      private void init_from_info (DesktopFileInfo info)
      {
        this.title = info.name;
        this.description = info.comment;
        this.icon_name = info.icon_name;
        this.exec = info.exec;
        this.needs_terminal = info.needs_terminal;
        this.title_folded = info.get_name_folded ();
        this.title_unaccented = Utils.remove_accents (this.title_folded);
        this.desktop_id = "application://" + info.desktop_id;
        this.generic_name = info.generic_name;
      }
    }

    static void register_plugin ()
    {
      DataSink.PluginRegistry.get_default ().register_plugin (
        typeof (DesktopFilePlugin),
        "Application Search",
        _ ("Search for and run applications on your computer."),
        "system-run",
        register_plugin
      );
    }
    
    static construct
    {
      register_plugin ();
    }
    
    private Gee.List<DesktopFileMatch> desktop_files;

    construct
    {
      desktop_files = new Gee.ArrayList<DesktopFileMatch> ();
      mimetype_map = new Gee.HashMap<string, OpenWithAction> ();

      var dfs = DesktopFileService.get_default ();
      dfs.reload_started.connect (() => {
        loading_in_progress = true;
      });
      dfs.reload_done.connect (() => {
        mimetype_map.clear ();
        desktop_files.clear ();
        load_all_desktop_files.begin ();
      });

      load_all_desktop_files.begin ();
    }

    public signal void load_complete ();
    private bool loading_in_progress = false;

    private async void load_all_desktop_files ()
    {
      loading_in_progress = true;
      Idle.add_full (Priority.LOW, load_all_desktop_files.callback);
      yield;

      var dfs = DesktopFileService.get_default ();

      foreach (DesktopFileInfo dfi in dfs.get_desktop_files ())
      {
        desktop_files.add (new DesktopFileMatch.for_info (dfi));
      }

      loading_in_progress = false;
      load_complete ();
    }
    
    private int compute_relevancy (DesktopFileMatch dfm, int base_relevancy)
    {
      var rs = RelevancyService.get_default ();
      float popularity = rs.get_application_popularity (dfm.desktop_id);

      int r = RelevancyService.compute_relevancy (base_relevancy, popularity);
      Utils.Logger.debug (this, "relevancy for %s: %d", dfm.desktop_id, r);
      
      return r;
    }

    private void full_search (Query q, ResultSet results,
                              MatcherFlags flags = 0)
    {
      // try to match against global matchers and if those fail, try also exec
      var matchers = Query.get_matchers_for_query (q.query_string_folded,
                                                   flags);

      foreach (var dfm in desktop_files)
      {
        unowned string folded_title = dfm.get_title_folded ();
        unowned string unaccented_title = dfm.title_unaccented;
        unowned string comment = dfm.description;
        unowned string generic_name = dfm.generic_name;

        bool matched = false;
        // FIXME: we need to do much smarter relevancy computation in fuzzy re
        // "sysmon" matching "System Monitor" is very good as opposed to
        // "seto" matching "System Monitor"
        foreach (var matcher in matchers)
        {
          MatchInfo info;
          if (matcher.key.match (folded_title, 0, out info))
          {
            results.add (dfm, compute_relevancy (dfm, matcher.value));
            matched = true;
            break;
          }
          else if (unaccented_title != null && matcher.key.match (unaccented_title))
          {
            results.add (dfm, compute_relevancy (dfm, matcher.value - Match.Score.INCREMENT_SMALL));
            matched = true;
            break;
          } 
          else if (info.is_partial_match ())
          {
            results.add (dfm, compute_relevancy (dfm, Match.Score.INCREMENT_SMALL));
            matched = true;
            break;
          }
        }

        string id = dfm.desktop_id.replace ("application://", "");
        var desktop_app_info = new DesktopAppInfo (id);
        string[] actions = desktop_app_info.list_actions ();
        foreach (string action in actions) {
          string title = desktop_app_info.get_action_name (action).down ();
          foreach (var matcher in matchers)
          {
            MatchInfo action_info;
            if (matcher.key.match (title, 0, out action_info)
                || title.contains (q.query_string_folded)
                || title.has_prefix (q.query_string))
            {
              var am = new ActionMatch (id, action);
              results.add (am, compute_relevancy (dfm, Match.Score.INCREMENT_SMALL));
              matched = true;
              break;
            }

            else if (action_info.is_partial_match ())
            {
              var am = new ActionMatch (id, action);
              results.add (am, compute_relevancy (dfm, Match.Score.INCREMENT_SMALL));
              matched = true;  
              break;        
            }
          }
        }

        if (!matched && (comment.down ().contains (q.query_string_folded) 
            || generic_name.down ().contains (q.query_string_folded)))
        {
            results.add (dfm, compute_relevancy (dfm, Match.Score.AVERAGE - Match.Score.INCREMENT_MEDIUM));
            matched = true;
        }
        if (!matched && dfm.exec.has_prefix (q.query_string))
        {
          results.add (dfm, compute_relevancy (dfm, dfm.exec == q.query_string ?
            Match.Score.VERY_GOOD : Match.Score.AVERAGE - Match.Score.INCREMENT_SMALL));
        }
      }
    }

    public bool handles_query (Query q)
    {
      // we only search for applications
      if (!(QueryFlags.APPLICATIONS in q.query_type)) return false;
      if (q.query_string.strip () == "") return false;

      return true;
    }

    public async ResultSet? search (Query q) throws SearchError
    {
      if (loading_in_progress)
      {
        // wait
        ulong signal_id = this.load_complete.connect (() =>
        {
          search.callback ();
        });
        yield;
        SignalHandler.disconnect (this, signal_id);
      }
      else
      {
        // we'll do this so other plugins can send their DBus requests etc.
        // and they don't have to wait for our blocking (though fast) search
        // to finish
        Idle.add_full (Priority.HIGH_IDLE, search.callback);
        yield;
      }

      q.check_cancellable ();

      // FIXME: spawn new thread and do the search there?
      var result = new ResultSet ();

      // FIXME: make sure this is one unichar, not just byte
      if (q.query_string.length == 1)
      {
        var flags = MatcherFlags.NO_SUBSTRING | MatcherFlags.NO_PARTIAL |
                    MatcherFlags.NO_FUZZY;
        full_search (q, result, flags);
      }
      else
      {
        full_search (q, result);
      }

      q.check_cancellable ();

      return result;
    }
    
    private class OpenWithAction: Object, Match
    {
       // for Match interface
      public string title { get; construct set; }
      public string description { get; set; default = ""; }
      public string icon_name { get; construct set; default = ""; }
      public bool has_thumbnail { get; construct set; default = false; }
      public string thumbnail_path { get; construct set; }
      public MatchType match_type { get; construct set; }
      
      public DesktopFileInfo desktop_info { get; private set; }
      
      public OpenWithAction (DesktopFileInfo info)
      {
        Object ();
        
        init_with_info (info);
      }

      private void init_with_info (DesktopFileInfo info)
      {
        this.title = _ ("Open with %s").printf (info.name);
        this.icon_name = info.icon_name;
        this.description = _ ("Opens current selection using %s").printf (info.name);
        this.desktop_info = info;
      }
      
      protected void execute (Match? match)
      {
        UriMatch uri_match = match as UriMatch;
        return_if_fail (uri_match != null);
        
        var f = File.new_for_uri (uri_match.uri);
        try
        {
          var app_info = new DesktopAppInfo.from_filename (desktop_info.filename);
          List<File> files = new List<File> ();
          files.prepend (f);
          app_info.launch (files, Gdk.Display.get_default ().get_app_launch_context ());
        }
        catch (Error err)
        {
          warning ("%s", err.message);
        }
      }
    }
    
    private Gee.Map<string, Gee.List<OpenWithAction> > mimetype_map;

    public ResultSet? find_for_match (ref Query query, Match match)
    {
      if (match.match_type != MatchType.GENERIC_URI) return null;

      var uri_match = match as UriMatch;
      return_val_if_fail (uri_match != null, null);
      
      if (uri_match.mime_type == null) return null;

      Gee.List<OpenWithAction> ow_list = mimetype_map[uri_match.mime_type];
      /* Query DesktopFileService only if is necessary */
      if (ow_list == null)
      {
        /* Initialize ow_list */
        ow_list = new Gee.LinkedList<OpenWithAction> ();
        mimetype_map[uri_match.mime_type] = ow_list;
        var dfs = DesktopFileService.get_default ();
        var list_for_mimetype = dfs.get_desktop_files_for_type (uri_match.mime_type);
        /* If there's more than one application, fill the ow list */
        if (list_for_mimetype.size > 1)
        {
          foreach (var entry in list_for_mimetype)
          {
            ow_list.add (new OpenWithAction (entry));
          }
        }
        else return null;
      }
      else if (ow_list.size == 0) return null;

      var rs = new ResultSet ();
      
      if (query.query_string == "")
      {
        foreach (var action in ow_list)
        {
          rs.add (action, Match.Score.POOR);
        }
      }
      else
      {
        var matchers = Query.get_matchers_for_query (query.query_string, 0,
          RegexCompileFlags.OPTIMIZE | RegexCompileFlags.CASELESS);
        foreach (var action in ow_list)
        {
          foreach (var matcher in matchers)
          {
            if (matcher.key.match (action.title))
            {
              rs.add (action, matcher.value);
              break;
            }
          }
        }
      }

      return rs;
    }
  }
}
