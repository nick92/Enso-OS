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
 * Authored by Magnus Kulke <mkulke@gmail.com>
 *
 */

namespace Synapse
{
  public class CalculatorPlugin: Object, Activatable, ItemProvider
  {
    public bool enabled { get; set; default = true; }

    public void activate ()
    {
      
    }

    public void deactivate ()
    {
      
    }

    private class Result: Object, Match
    {
      // from Match interface
      public string title { get; construct set; }
      public string description { get; set; }
      public string icon_name { get; construct set; }
      public bool has_thumbnail { get; construct set; }
      public string thumbnail_path { get; construct set; }
      public MatchType match_type { get; construct set; }

      public int default_relevancy { get; set; default = 0; }

      public Result (double result, string match_string)
      {
        Object (match_type: MatchType.TEXT,
                title: "%g".printf (result),
                description: "%s = %g".printf (match_string, result),
                has_thumbnail: false, icon_name: "accessories-calculator");
      }
    }

    static void register_plugin ()
    {
      DataSink.PluginRegistry.get_default ().register_plugin (
        typeof (CalculatorPlugin),
        _ ("Calculator"),
        _ ("Calculate basic expressions."),
        "accessories-calculator",
        register_plugin,
        Environment.find_program_in_path ("bc") != null,
        _ ("bc is not installed")
      );
    }

    static construct
    {
      register_plugin ();
    }

    private Regex regex;

    construct
    {
      /* The regex describes a string which *resembles* a mathematical expression. It does not
         check for pairs of parantheses to be used correctly and only whitespace-stripped strings
         will match. Basically it matches strings of the form: 
         "paratheses_open* number (operator paratheses_open* number paratheses_close*)+"
      */
      try
      {
        regex = new Regex ("^\\(*(-?\\d+([.,]\\d+)?)([*/+-^]\\(*(-?\\d+([.,]\\d+)?)\\)*)+$",
                         RegexCompileFlags.OPTIMIZE);
      } catch (Error e) {
        Utils.Logger.error (this, "Error creating regexp.");
      }
    }
    
    public bool handles_query (Query query)
    {
      return (QueryFlags.ACTIONS in query.query_type);
    }

    public async ResultSet? search (Query query) throws SearchError
    { 
      string input = query.query_string.replace (" ", "").replace (",", ".");
      bool matched = regex.match (input);
      if (!matched && input.length > 1)
      {
        input = input[0 : input.length - 1];
        matched = regex.match (input);
      }
      if (matched)
      {
        Pid pid;
        int read_fd, write_fd;
        string[] argv = {"bc", "-l"};
        string? solution = null;

        try
        {
          Process.spawn_async_with_pipes (null, argv, null,
                                          SpawnFlags.SEARCH_PATH,
                                          null, out pid, out write_fd, out read_fd);
          UnixInputStream read_stream = new UnixInputStream (read_fd, true);
          DataInputStream bc_output = new DataInputStream (read_stream);

          UnixOutputStream write_stream = new UnixOutputStream (write_fd, true);
          DataOutputStream bc_input = new DataOutputStream (write_stream);

          bc_input.put_string (input + "\n", query.cancellable);
          yield bc_input.close_async (Priority.DEFAULT, query.cancellable);
          solution = yield bc_output.read_line_async (Priority.DEFAULT_IDLE, query.cancellable);

          if (solution != null)
          {
            double d = double.parse (solution);
            Result result = new Result (d, query.query_string);
            ResultSet results = new ResultSet ();
            results.add (result, Match.Score.AVERAGE);
            query.check_cancellable ();
            return results;
          }
        }
        catch (Error err)
        {
          if (!query.is_cancelled ()) warning ("%s", err.message);
        }
      }

      query.check_cancellable ();
      return null;
    }
  }
}
