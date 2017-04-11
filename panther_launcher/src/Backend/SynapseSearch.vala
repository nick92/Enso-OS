// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//
//  Copyright (C) 2011-2012 Giulio Collura
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

using Soup;

namespace Panther.Backend {

    public class SynapseSearch : Object {

        private static Type[] plugins = {
            typeof (Synapse.CalculatorPlugin),
            typeof (Synapse.CommandPlugin),
            typeof (Synapse.DesktopFilePlugin),
            typeof (Synapse.SystemManagementPlugin)
        };

        private static Synapse.DataSink? sink = null;
        private static Gee.HashMap<string,Gdk.Pixbuf> favicon_cache;

        Cancellable? current_search = null;

        public SynapseSearch () {

            if (sink == null) {
                sink = new Synapse.DataSink ();
                foreach (var plugin in plugins) {
                    sink.register_static_plugin (plugin);
                }

                favicon_cache = new Gee.HashMap<string,Gdk.Pixbuf> ();
            }
        }

        public async Gee.List<Synapse.Match>? search (string text, Synapse.SearchProvider? provider = null) {

            if (current_search != null)
                current_search.cancel ();

            if (provider == null)
                provider = sink;

            var results = new Synapse.ResultSet ();

            try {
                return yield provider.search (text, Synapse.QueryFlags.ALL, results, current_search);
            } catch (Error e) { warning (e.message); }

            return null;
        }

        public static Gee.List<Synapse.Match> find_actions_for_match (Synapse.Match match) {
            return sink.find_actions_for_match (match, null, Synapse.QueryFlags.ALL);
        }

        /**
         * Attempts to load a favicon for an UriMatch and caches the icon
         *
         * @param match       The UriMatch
         * @param size        The icon size at which to load the icon. If the favicon is smaller than
         *                    that size, null will be returned
         * @param cancellable Cancellable for the loading operations
         * @return            The pixbuf or null if loading failed or the icon was too small
         */
        public static async Gdk.Pixbuf? get_favicon_for_match (Synapse.UriMatch match, int size,
            Cancellable? cancellable = null) {

            var soup_uri = new Soup.URI (match.uri);
            if (!soup_uri.scheme.has_prefix ("http"))
                return null;

            Gdk.Pixbuf? pixbuf = null;

            if (favicon_cache.has_key (soup_uri.host))
                return favicon_cache.get (soup_uri.host);

            var url = "%s://%s/favicon.ico".printf (soup_uri.scheme, soup_uri.host);

            var msg = new Soup.Message ("GET", url);
            var session = new Soup.Session ();
            session.use_thread_context = true;

            try {
                var stream = yield session.send_async (msg, cancellable);
                if (stream != null) {
                    pixbuf = yield new Gdk.Pixbuf.from_stream_async (stream, cancellable);
                    // as per design decision, icons that are smaller than requested will not
                    // be displayed, instead the fallback should be used, so we return null
                    if (pixbuf.width < size)
                        pixbuf = null;
                }
            } catch (Error e) {}

            if (cancellable.is_cancelled ())
                return null;

            // we set the cache in any case, even if things failed. No need to
            // try requesting an icon again and again
            favicon_cache.set (soup_uri.host, pixbuf);

            return pixbuf;
        }

        // copied from synapse-ui with some slight changes
        public static string markup_string_with_search (string text, string pattern) {

            string markup = "%s";

            if (pattern == "") {
                return markup.printf (Markup.escape_text (text));
            }

            // if no text found, use pattern
            if (text == "") {
                return markup.printf (Markup.escape_text (pattern));
            }

            var matchers = Synapse.Query.get_matchers_for_query (pattern, 0,
                RegexCompileFlags.OPTIMIZE | RegexCompileFlags.CASELESS);

            string? highlighted = null;
            foreach (var matcher in matchers) {
                MatchInfo mi;
                if (matcher.key.match (text, 0, out mi)) {
                    int start_pos;
                    int end_pos;
                    int last_pos = 0;
                    int cnt = mi.get_match_count ();
                    StringBuilder res = new StringBuilder ();
                    for (int i = 1; i < cnt; i++) {
                        mi.fetch_pos (i, out start_pos, out end_pos);
                        warn_if_fail (start_pos >= 0 && end_pos >= 0);
                        res.append (Markup.escape_text (text.substring (last_pos, start_pos - last_pos)));
                        last_pos = end_pos;
                        res.append (Markup.printf_escaped ("<b>%s</b>", mi.fetch (i)));
                        if (i == cnt - 1) {
                            res.append (Markup.escape_text (text.substring (last_pos)));
                        }
                    }
                    highlighted = res.str;
                    break;
                }
            }

            if (highlighted != null) {
                return markup.printf (highlighted);
            } else {
                return markup.printf (Markup.escape_text(text));
            }
        }
    }
}

