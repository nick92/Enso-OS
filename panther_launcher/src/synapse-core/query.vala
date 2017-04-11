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
  [Flags]
  public enum QueryFlags
  {
    /* HowTo create categories (32bit).
     * Authored by Alberto Aldegheri <albyrock87+dev@gmail.com>
     * Categories are "stored" in 3 Levels:
     *  Super-Category
     *  -> Category
     *  ----> Sub-Category
     * ------------------------------------
     * if (Super-Category does NOT have childs):
     *    SUPER = 1 << FreeBitPosition
     * else:
     *    if (Category does NOT have childs)
     *      CATEGORY = 1 << FreeBitPosition
     *    else
     *      SUB = 1 << FreeBitPosition
     *      CATEGORY = OR ([subcategories, ...]);
     *
     *    SUPER = OR ([categories, ...]);
     *
     *
     * Remember: 
     *   if you add or remove a category, 
     *   change labels in UIInterface.CategoryConfig.init_labels
     *
     */
    INCLUDE_REMOTE  = 1 << 0,
    UNCATEGORIZED   = 1 << 1,

    APPLICATIONS    = 1 << 2,
    
    ACTIONS         = 1 << 3,
    
      AUDIO           = 1 << 4,
      VIDEO           = 1 << 5,
      DOCUMENTS       = 1 << 6,
      IMAGES          = 1 << 7,
    FILES           = AUDIO | VIDEO | DOCUMENTS | IMAGES,
    
    PLACES          = 1 << 8,

    // FIXME: shouldn't this be FILES | INCLUDE_REMOTE?
    INTERNET        = 1 << 9,
    
    // FIXME: Text Query flag? kinda weird, why do we have this here?
    TEXT            = 1 << 10,
    
    CONTACTS        = 1 << 11,

    ALL           = 0xFFFFFFFF,
    LOCAL_CONTENT = ALL ^ QueryFlags.INCLUDE_REMOTE
  }
  
  [Flags]
  public enum MatcherFlags
  {
    NO_REVERSED   = 1 << 0,
    NO_SUBSTRING  = 1 << 1,
    NO_PARTIAL    = 1 << 2,
    NO_FUZZY      = 1 << 3
  }

  public struct Query
  {
    string query_string;
    string query_string_folded;
    Cancellable cancellable;
    QueryFlags query_type;
    uint max_results;
    uint query_id;

    public Query (uint query_id,
                  string query,
                  QueryFlags flags = QueryFlags.LOCAL_CONTENT,
                  uint num_results = 96)
    {
      this.query_id = query_id;
      this.query_string = query;
      this.query_string_folded = query.casefold ();
      this.query_type = flags;
      this.max_results = num_results;
    }

    public bool is_cancelled ()
    {
      return cancellable.is_cancelled ();
    }

    public void check_cancellable () throws SearchError
    {
      if (cancellable.is_cancelled ())
      {
        throw new SearchError.SEARCH_CANCELLED ("Cancelled");
      }
    }

    public static Gee.List<Gee.Map.Entry<Regex, int>>
    get_matchers_for_query (string query,
                            MatcherFlags match_flags = 0,
                            RegexCompileFlags flags = GLib.RegexCompileFlags.OPTIMIZE)
    {
      /* create a couple of regexes and try to help with matching
       * match with these regular expressions (with descending score):
       * 1) ^query$
       * 2) ^query
       * 3) \bquery
       * 4) split to words and seach \bword1.+\bword2 (if there are 2+ words)
       * 5) query
       * 6) split to characters and search \bq.+\bu.+\be.+\br.+\by
       * 7) split to characters and search \bq.*u.*e.*r.*y
       *
       * The set of returned regular expressions depends on MatcherFlags.
       */

      var results = new Gee.HashMap<Regex, int> ();
      Regex re;

      try
      {
        re = new Regex ("^(%s)$".printf (Regex.escape_string (query)), flags);
        results[re] = Match.Score.HIGHEST;
      }
      catch (RegexError err)
      {
      }

      try
      {
        re = new Regex ("^(%s)".printf (Regex.escape_string (query)), flags);
        results[re] = Match.Score.EXCELLENT;
      }
      catch (RegexError err)
      {
      }

      try
      {
        re = new Regex ("\\b(%s)".printf (Regex.escape_string (query)), flags);
        results[re] = Match.Score.VERY_GOOD;
      }
      catch (RegexError err)
      {
      }

      // split to individual chars
      string[] individual_words = Regex.split_simple ("\\s+", query.strip ());
      if (individual_words.length >= 2)
      {
        string[] escaped_words = {};
        foreach (unowned string word in individual_words)
        {
          escaped_words += Regex.escape_string (word);
        }
        string pattern = "\\b(%s)".printf (string.joinv (").+\\b(",
                                                         escaped_words));

        try
        {
          re = new Regex (pattern, flags);
          results[re] = Match.Score.GOOD;
        }
        catch (RegexError err)
        {
        }

        // FIXME: do something generic here
        if (!(MatcherFlags.NO_REVERSED in match_flags))
        {
          if (escaped_words.length == 2)
          {
            var reversed = "\\b(%s)".printf (string.join (").+\\b(",
                                                        escaped_words[1],
                                                        escaped_words[0],
                                                        null));
            try
            {
              re = new Regex (reversed, flags);
              results[re] = Match.Score.GOOD - Match.Score.INCREMENT_MINOR;
            }
            catch (RegexError err)
            {
            }
          }
          else
          {
            // not too nice, but is quite fast to compute
            var orred = "\\b((?:%s))".printf (string.joinv (")|(?:", escaped_words));
            var any_order = "";
            for (int i=0; i<escaped_words.length; i++)
            {
              bool is_last = i == escaped_words.length - 1;
              any_order += orred;
              if (!is_last) any_order += ".+";
            }
            try
            {
              re = new Regex (any_order, flags);
              results[re] = Match.Score.AVERAGE + Match.Score.INCREMENT_MINOR;
            }
            catch (RegexError err)
            {
            }
          }
        }
      }
      
      if (!(MatcherFlags.NO_SUBSTRING in match_flags))
      {
        try
        {
          re = new Regex ("(%s)".printf (Regex.escape_string (query)), flags);
          results[re] = Match.Score.BELOW_AVERAGE;
        }
        catch (RegexError err)
        {
        }
      }

      // split to individual characters
      string[] individual_chars = Regex.split_simple ("\\s*", query);
      string[] escaped_chars = {};
      foreach (unowned string word in individual_chars)
      {
        escaped_chars += Regex.escape_string (word);
      }

      // make  "aj" match "Activity Journal"
      if (!(MatcherFlags.NO_PARTIAL in match_flags) &&
          individual_words.length == 1 && individual_chars.length <= 5)
      {
        string pattern = "\\b(%s)".printf (string.joinv (").+\\b(",
                                                         escaped_chars));
        try
        {
          re = new Regex (pattern, flags);
          results[re] = Match.Score.ABOVE_AVERAGE;
        }
        catch (RegexError err)
        {
        }
      }

      if (!(MatcherFlags.NO_FUZZY in match_flags) && escaped_chars.length > 0)
      {
        string pattern = "\\b(%s)".printf (string.joinv (").*(",
                                                         escaped_chars));
        try
        {
          re = new Regex (pattern, flags);
          results[re] = Match.Score.POOR;
        }
        catch (RegexError err)
        {
        }
      }

      var sorted_results = new Gee.ArrayList<Gee.Map.Entry<Regex, int>> ();
      var entries = results.entries;
      // FIXME: why it doesn't work without this?
      sorted_results.set_data ("entries-ref", entries);
      sorted_results.add_all (entries);
      sorted_results.sort ((a, b) =>
      {
        unowned Gee.Map.Entry<Regex, int> e1 = (Gee.Map.Entry<Regex, int>) a;
        unowned Gee.Map.Entry<Regex, int> e2 = (Gee.Map.Entry<Regex, int>) b;
        return e2.value - e1.value;
      });

      return sorted_results;
    }
  }
}

