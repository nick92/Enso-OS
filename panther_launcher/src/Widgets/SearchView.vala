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

using Gtk;

namespace Panther.Widgets {

    public class SearchView : Gtk.ScrolledWindow {
        const int MAX_RESULTS = 20;
        const int MAX_RESULTS_BEFORE_LIMIT = 10;

        public signal void start_search (Synapse.SearchMatch search_match, Synapse.Match? target);

        public bool in_context_view { get; private set; default = false; }

        private Gee.HashMap<Backend.App, SearchItem> items;
        private SearchItem selected_app = null;
        private Gtk.Box main_box;

        private Gtk.Box context_box;
        private Gtk.Fixed context_fixed;
        private int context_selected_y;

        private int n_results = 0;

        private int _selected = 0;
        public int selected {
            get {
                return _selected;
            }
            set {
                _selected = value;
                var max_index = (int)n_results - 1;

                // cycle
                if (_selected < 0)
                    _selected = max_index;
                else if (_selected > max_index)
                    _selected = 0;

                select_nth (main_box, _selected);

                if (in_context_view)
                    toggle_context (false);
            }
        }

        private int _context_selected = 0;
        public int context_selected {
            get {
                return _context_selected;
            }
            set {
                _context_selected = value;
                var max_index = (int)context_box.get_children ().length () - 1;

                // cycle
                if (_context_selected < 0)
                    _context_selected = max_index;
                else if (_context_selected > max_index)
                    _context_selected = 0;

                select_nth (context_box, _context_selected);
            }
        }

        public signal void app_launched ();

        private PantherView view;

        public SearchView (PantherView parent) {
            view = parent;
            hscrollbar_policy = Gtk.PolicyType.NEVER;
            items = new Gee.HashMap<Backend.App, SearchItem> ();

            main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            main_box.margin_start = 12;

            context_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            context_fixed = new Gtk.Fixed ();
            context_fixed.margin_start = 12;
            context_fixed.put (context_box, 0, 0);

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.pack_start (main_box, true);
            box.pack_start (context_fixed, false);

            add_with_viewport (box);

            parent.search_entry.key_press_event.connect ((e) => {
                if (parent.search_entry.text == "")
                    _selected = 0;

                return false;
            });
        }

        public void set_results (Gee.List<Synapse.Match> matches, string search_term) {
            // we have a hashmap of the categories with their matches and keep
            // their order in a separate list, as the keys list of the map does
            // not always keep the same order in which the keys were added
            var categories = new HashTable<int,Gee.LinkedList<Synapse.Match>> (null, null);
            var categories_order = new Gee.LinkedList<int> ();

            foreach (var match in matches) {
                Gee.LinkedList<Synapse.Match> list = null;

                // we're cheating here to give remote results a separate category. We assign 8 as
                // the id for internet results, which currently is the lowest undefined MatchType
                int type = match.match_type;
                if (type == Synapse.MatchType.GENERIC_URI) {
                    var uri = (match as Synapse.UriMatch).uri;
                    if (uri.has_prefix ("http://")
                        || uri.has_prefix ("ftp://")
                        || uri.has_prefix ("https://"))
                        type = 8;
                }

                if (match is Synapse.DesktopFilePlugin.ActionMatch)
                    type = 10;

                if ((list = categories.get (type)) == null) {
                    list = new Gee.LinkedList<Synapse.Match> ();
                    categories.set (type, list);
                    categories_order.add (type);
                }

                list.add (match);
            }

            n_results = 0;
            clear ();

            // if we're showing more than about 10 results and we have more than
            // categories, we limit the results per category to the most relevant
            // ones.
            var limit = MAX_RESULTS;
            if (matches.size + 3 > MAX_RESULTS_BEFORE_LIMIT && categories_order.size > 2)
                limit = 5;

            foreach (var type in categories_order) {
                string label = "";

                switch (type) {
                    case Synapse.MatchType.UNKNOWN:
                        label = _("Other");
                        break;
                    case Synapse.MatchType.TEXT:
                        label = _("Text");
                        break;
                    case Synapse.MatchType.APPLICATION:
                        label = _("Applications");
                        break;
                    case Synapse.MatchType.GENERIC_URI:
                        label = _("Files");
                        break;
                    case Synapse.MatchType.ACTION:
                        label = _("Actions");
                        break;
                    case Synapse.MatchType.SEARCH:
                        label = _("Search");
                        break;
                    case Synapse.MatchType.CONTACT:
                        label = _("Contacts");
                        break;
                    case 8:
                        label = _("Internet");
                        break;
                    case 10:
                        label = _("Application Actions");
                        break;
                }

                var header = new Gtk.Label (label);
                ((Gtk.Misc) header).xalign = 0.0f;
                header.margin_start = 8;
                header.margin_bottom = 4;
                header.use_markup = true;
                header.get_style_context ().add_class ("h4");
                header.show ();
                main_box.pack_start (header, false);

                var list = categories.get (type);
                var old_selected = selected;
                for (var i = 0; i < limit && i < list.size; i++) {
                    var match = list.get (i);
                    if (type == 10) {
                        show_action (new Backend.App.from_synapse_match (match));
                        n_results++;
                        continue;
                    }
                    // expand the actions we get for UNKNOWN
                    if (match.match_type == Synapse.MatchType.UNKNOWN) {
                        var actions = Backend.SynapseSearch.find_actions_for_match (match);
                        foreach (var action in actions) {
                            show_app (new Backend.App.from_synapse_match (action, match), search_term);
                            n_results++;
                        }
                    } else {
                        show_app (new Backend.App.from_synapse_match (match), search_term);
                        n_results++;
                    }
                }
                selected = old_selected;
            }
        }

        private void show_app (Backend.App app, string search_term) {

            var search_item = new SearchItem (app, search_term);
            app.start_search.connect ((search, target) => start_search (search, target));
            search_item.button_release_event.connect (() => {
                if (!search_item.dragging) {
                    app.launch ();
                    app_launched ();
                }
                return true;
            });

            main_box.pack_start (search_item, false, false);
            search_item.show_all ();

            items[app] = search_item;

        }

        private void show_action (Backend.App app) {
            var search_item = new SearchItem (app, "", true, app.match.title);
            app.start_search.connect ((search, target) => start_search (search, target));
            search_item.button_release_event.connect (() => {
                if (!search_item.dragging) {
                    ((Synapse.DesktopFilePlugin.ActionMatch) app.match).execute (null);
                    app_launched ();
                }

                return true;
            });

            main_box.pack_start (search_item, false, false);
            search_item.show_all ();

            items[app] = search_item;        
        }


        public void toggle_context (bool show) {
            var prev_y = vadjustment.value;

            if (show && in_context_view == false) {
                if (selected_app.app.match.match_type == Synapse.MatchType.ACTION)
                    return;

                in_context_view = true;

                foreach (var child in context_box.get_children ())
                    context_box.remove (child);

                var actions = Backend.SynapseSearch.find_actions_for_match (selected_app.app.match);
                foreach (var action in actions) {
                    var app = new Backend.App.from_synapse_match (action, selected_app.app.match);
                    app.start_search.connect ((search, target) => start_search (search, target));
                    context_box.pack_start (new SearchItem (app));
                }
                context_box.show_all ();

                Gtk.Allocation alloc;
                selected_app.get_allocation (out alloc);

                context_fixed.move (context_box, 0, alloc.y);
                context_selected_y = alloc.y;

                context_selected = 0;
            } else {
                in_context_view = false;

                // trigger update of selection
                selected = selected;
            }

            vadjustment.value = prev_y;
        }

        public void clear () {
            if (in_context_view)
                toggle_context (false);

            foreach (var child in main_box.get_children ())
                child.destroy ();
        }

        public void down () {
            if (in_context_view)
                context_selected ++;
            else
                selected++;
        }

        public void up () {
            if (in_context_view)
                context_selected--;
            else
                selected--;
        }

        private void select_nth (Gtk.Box box, int index) {

            if (selected_app != null)
                // enable to make main item stay blue
                // && !(box == context_box && selected_app.get_parent () == main_box))
                selected_app.unset_state_flags (Gtk.StateFlags.PRELIGHT);

            if (box == main_box)
                selected_app = get_nth_main_item (index) as SearchItem;
            else
                selected_app = box.get_children ().nth_data (index) as SearchItem;

            selected_app.set_state_flags (Gtk.StateFlags.PRELIGHT, true);

            Gtk.Allocation alloc;
            selected_app.get_allocation (out alloc);

            vadjustment.value = double.max (alloc.y - vadjustment.page_size / 2, 0);
        }

        private Gtk.Widget? get_nth_main_item (int n) {
            var i = 0;
            foreach (var child in main_box.get_children ()) {
                if (i == n && child is SearchItem)
                    return child;

                if (child is SearchItem)
                    i++;
            }

            return null;
        }

        /**
         * Launch selected app
         *
         * @return indicates whether panther should now be hidden
         */
        public bool launch_selected () {
            if (selected_app.action) {
                ((Synapse.DesktopFilePlugin.ActionMatch) selected_app.app.match).execute (null);
                return true;
            }
            return selected_app.launch_app ();

        }

    }

}
