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

    public class SearchItem : Gtk.Button {

        const int ICON_SIZE = 32;

        public Backend.App app { get; construct; }

        private Gtk.Label name_label;
        private Gtk.Image icon;

        private Cancellable? cancellable = null;
        public bool dragging = false; //prevent launching
        public bool action = false;

        public signal bool launch_app ();

        public SearchItem (Backend.App app, string search_term = "", bool action = false, string action_title = "") {
            Object (app: app);
            
            this.action = action;
            get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

            string markup;
            if (action)
                markup = action_title;
            else
                markup = Backend.SynapseSearch.markup_string_with_search (app.name, search_term);

            name_label = new Gtk.Label (markup);
            name_label.set_ellipsize (Pango.EllipsizeMode.END);
            name_label.use_markup = true;
            ((Gtk.Misc) name_label).xalign = 0.0f;

            icon = new Gtk.Image.from_pixbuf (app.load_icon (ICON_SIZE));

            // load a favicon if we're an internet page
            var uri_match = app.match as Synapse.UriMatch;
            if (uri_match != null && uri_match.uri.has_prefix ("http")) {
                cancellable = new Cancellable ();
                Backend.SynapseSearch.get_favicon_for_match.begin (uri_match,
                    ICON_SIZE, cancellable, (obj, res) => {

                    var pixbuf = Backend.SynapseSearch.get_favicon_for_match.end (res);
                    if (pixbuf != null)
                        icon.set_from_pixbuf (pixbuf);
                });
            }

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            box.pack_start (icon, false);
            box.pack_start (name_label, true);
            box.margin_start = 12;
            box.margin_top = box.margin_bottom = 3;

            add (box);

            if (!action)
                launch_app.connect (app.launch);

            var app_match = app.match as Synapse.ApplicationMatch;
            if (app_match != null) {
                Gtk.TargetEntry dnd = {"text/uri-list", 0, 0};
                Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, {dnd},
                Gdk.DragAction.COPY);
                this.drag_begin.connect ( (ctx) => {
                    this.dragging = true;
                    Gtk.drag_set_icon_pixbuf (ctx, app.icon, 0, 0);
                });
                this.drag_end.connect ( () => {
                    this.dragging = false;
                });
                this.drag_data_get.connect ( (ctx, sel, info, time) => {
                    sel.set_uris ({File.new_for_path (app_match.filename).get_uri ()});
                });
            }
           
        }

        public override void destroy () {

            base.destroy ();

            if (cancellable != null)
                cancellable.cancel ();
        }
    }

}
