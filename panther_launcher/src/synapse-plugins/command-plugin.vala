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
  public class CommandPlugin: Object, Activatable, ItemProvider
  {
    public bool enabled { get; set; default = true; }

    public void activate ()
    {
      
    }

    public void deactivate ()
    {
      
    }

    private class CommandObject: Object, Match, ApplicationMatch
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
      public string? filename { get; construct set; default = null; }
      public string command { get; construct set; }
      
      public CommandObject (string cmd)
      {
        Object (title: _("Execute '%s'").printf (cmd), description: _ ("Run command"), command: cmd,
                icon_name: "application-x-executable",
                match_type: MatchType.APPLICATION,
                needs_terminal: cmd.has_prefix ("sudo "));

        try
        {
          app_info = AppInfo.create_from_commandline (cmd, null, 0);
        }
        catch (Error err)
        {
          warning ("%s", err.message);
        }
      }
    }
    
    static void register_plugin ()
    {
      DataSink.PluginRegistry.get_default ().register_plugin (
        typeof (CommandPlugin),
        "Command Search",
        _ ("Find and execute arbitrary commands."),
        "system-run",
        register_plugin
      );
    }
    
    static construct
    {
      register_plugin ();
    }

    private Gee.Set<string> past_commands;
    private Regex split_regex;

    construct
    {
      // TODO: load from configuration
      past_commands = new Gee.HashSet<string> ();
      try
      {
        split_regex = new Regex ("\\s+", RegexCompileFlags.OPTIMIZE);
      }
      catch (RegexError err)
      {
        critical ("%s", err.message);
      }
    }
    
    private CommandObject? create_co (string exec)
    {
      // ignore results that will be returned by DesktopFilePlugin
      // and at the same time look for hidden and no-display desktop files,
      // so we can display their info (title, comment, icon)
      var dfs = DesktopFileService.get_default ();
      var df_list = dfs.get_desktop_files_for_exec (exec);
      DesktopFileInfo? dfi = null;
      foreach (var df in df_list)
      {
        if (!df.is_hidden) return null; // will be handled by App plugin
        dfi = df;
      }

      var co = new CommandObject (exec);
      if (dfi != null)
      {
        co.title = dfi.name;
        if (dfi.comment != "") co.description = dfi.comment;
        if (dfi.icon_name != null && dfi.icon_name != "") co.icon_name = dfi.icon_name;
      }

      return co;
    }
    
    private void command_executed (Match match)
    {
      CommandObject? co = match as CommandObject;
      if (co == null) return;

      past_commands.add (co.command);
    }

    public async ResultSet? search (Query q) throws SearchError
    {
      // we only search for applications
      if (!(QueryFlags.APPLICATIONS in q.query_type)) return null;

      Idle.add (search.callback);
      yield;

      var result = new ResultSet ();

      string stripped = q.query_string.strip ();
      if (stripped == "") return null;
      if (stripped.has_prefix ("~/"))
      {
        stripped = stripped.replace ("~", Environment.get_home_dir ());
      }

      if (!(stripped in past_commands))
      {
        foreach (var command in past_commands)
        {
          if (command.has_prefix (stripped))
          {
            result.add (create_co (command), Match.Score.AVERAGE);
          }
        }

        string[] args = split_regex.split (stripped);
        string? valid_cmd = Environment.find_program_in_path (args[0]);

        if (valid_cmd != null)
        {
          // don't allow dangerous commands
          if (args[0] == "rm") return null;
          CommandObject? co = create_co (stripped);
          if (co == null) return null;
          result.add (co, Match.Score.POOR);
          co.executed.connect (this.command_executed);
        }
      }
      else
      {
        result.add (create_co (stripped), Match.Score.VERY_GOOD);
      }
      
      q.check_cancellable ();

      return result;
    }
  }
}
