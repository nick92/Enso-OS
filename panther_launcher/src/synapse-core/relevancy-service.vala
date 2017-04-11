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
  public interface RelevancyBackend: Object
  {
    public abstract float get_application_popularity (string desktop_id);
    public abstract float get_uri_popularity (string uri);

    public abstract void application_launched (AppInfo app_info);
  }

  public class RelevancyService : GLib.Object
  {
    // singleton that can be easily destroyed
    private static unowned RelevancyService? instance;
    public static RelevancyService get_default ()
    {
      return instance ?? new RelevancyService ();
    }

    private RelevancyService ()
    {
    }

    ~RelevancyService ()
    {
    }

    construct
    {
      instance = this;
      this.add_weak_pointer (&instance);
      
      initialize_relevancy_backend ();
    }
    
    private RelevancyBackend backend;
    
    private void initialize_relevancy_backend ()
    {
#if HAVE_ZEITGEIST
      backend = new ZeitgeistRelevancyBackend ();
#else
      backend = null;
#endif
    }
    
    public float get_application_popularity (string desktop_id)
    {
      if (backend == null) return 0.0f;
      return backend.get_application_popularity (desktop_id);
    }

    public float get_uri_popularity (string uri)
    {
      if (backend == null) return 0.0f;
      return backend.get_uri_popularity (uri);
    }
    
    public void application_launched (AppInfo app_info)
    {
      Utils.Logger.debug (this, "application launched");
      if (backend == null) return;
      backend.application_launched (app_info);
    }

    public static int compute_relevancy (int base_relevancy, float modifier)
    {
      // FIXME: let's experiment here
      // the other idea is to use base_relevancy * (1.0f + modifier)
      int relevancy = (int) (base_relevancy + modifier * Match.Score.INCREMENT_LARGE * 2);
      //int relevancy = base_relevancy + (int) (modifier * Match.Score.HIGHEST);
      return relevancy;
      // FIXME: this clamping should be done, but it screws up the popularity
      //   for very popular items with high match score
      //return int.min (relevancy, Match.Score.HIGHEST);
    }
  }
}

