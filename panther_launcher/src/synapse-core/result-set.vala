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
  public class ResultSet : Object, Gee.Traversable<Match>, Gee.Iterable <Gee.Map.Entry <Match, int>>
  {
    protected Gee.Map<Match, int> matches;
    protected Gee.Set<unowned string> uris;

    public ResultSet ()
    {
      Object ();
    }

    construct
    {
      matches = new Gee.HashMap<Match, int> ();
      // Match.uri is not owned, so we can optimize here
      uris = new Gee.HashSet<unowned string> ();
    }

    public Type element_type
    {
      get { return matches.element_type; }
    }

    public int size
    {
      get { return matches.size; }
    }

    public Gee.Set<Match> keys
    {
      owned get { return matches.keys; }
    }

    public Gee.Set<Gee.Map.Entry <Match, int>> entries
    {
      owned get { return matches.entries; }
    }

    public Gee.Iterator<Gee.Map.Entry <Match, int>?> iterator ()
    {
      return matches.iterator ();
    }

    public bool foreach (Gee.ForallFunc<Match> func)
    {
        return matches.keys.foreach (func);
    }

    public void add (Match match, int relevancy)
    {
      matches.set (match, relevancy);

      if (match is UriMatch)
      {
        unowned string uri = (match as UriMatch).uri;
        if (uri != null && uri != "")
        {
          uris.add (uri);
        }
      }
    }

    public void add_all (ResultSet? rs)
    {
      if (rs == null) return;
      matches.set_all (rs.matches);
      uris.add_all (rs.uris);
    }

    public bool contains_uri (string uri)
    {
      return uri in uris;
    }

    public Gee.List<Match> get_sorted_list ()
    {
      var l = new Gee.ArrayList<Gee.Map.Entry<Match, int>> ();
      l.add_all (matches.entries);

      l.sort ((a, b) => 
      {
        unowned Gee.Map.Entry<Match, int> e1 = (Gee.Map.Entry<Match, int>) a;
        unowned Gee.Map.Entry<Match, int> e2 = (Gee.Map.Entry<Match, int>) b;
        int relevancy_delta = e2.value - e1.value;
        if (relevancy_delta != 0) return relevancy_delta;
        // FIXME: utf8 compare!
        else return e1.key.title.ascii_casecmp (e2.key.title);
      });

      var sorted_list = new Gee.ArrayList<Match> ();
      foreach (Gee.Map.Entry<Match, int> m in l)
      {
        sorted_list.add (m.key);
      }

      return sorted_list;
    }
  }
}

