//
//  Copyright (C) 2014 Tom Beckmann
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

using Clutter;
using Meta;

namespace Gala {
    /**
     * This class contains the icon groups at the bottom and will take
     * care of displaying actors for inserting windows between the groups
     * once implemented
     */
    public class IconGroupContainer : Actor {
        public const int SPACING = 48;
        public const int GROUP_WIDTH = 64;

        public signal void request_reposition (bool animate);

#if HAS_MUTTER330
        public Meta.Display display { get; construct; }
#else
        public Screen screen { get; construct; }
#endif

#if HAS_MUTTER330
        public IconGroupContainer (Meta.Display display) {
            Object (display: display);

            layout_manager = new BoxLayout ();
        }
#else
        public IconGroupContainer (Screen screen) {
            Object (screen: screen);

            layout_manager = new BoxLayout ();
        }
#endif

        public void add_group (IconGroup group) {
            var index = group.workspace.index ();

            insert_child_at_index (group, index * 2);

            var thumb = new WorkspaceInsertThumb (index);
            thumb.notify["expanded"].connect_after (expanded_changed);
            insert_child_at_index (thumb, index * 2);

            update_inserter_indices ();
        }

        public void remove_group (IconGroup group) {
            var thumb = (WorkspaceInsertThumb) group.get_previous_sibling ();
            thumb.notify["expanded"].disconnect (expanded_changed);
            remove_child (thumb);

            remove_child (group);

            update_inserter_indices ();
        }

        /**
         * Removes an icon group "in place".
         * When initially dragging an icon group we remove
         * it and it's previous WorkspaceInsertThumb. This would make
         * the container immediately reallocate and fill the empty space
         * with right-most IconGroups.
         * 
         * We don't want that until the IconGroup 
         * leaves the expanded WorkspaceInsertThumb.
         */
        public void remove_group_in_place (IconGroup group) {
            var deleted_thumb = (WorkspaceInsertThumb) group.get_previous_sibling ();
            var deleted_placeholder_thumb = (WorkspaceInsertThumb) group.get_next_sibling ();

            remove_group (group);

            /**
             * We will account for that empty space
             * by manually expanding the next WorkspaceInsertThumb with the
             * width we deleted. Because the IconGroup is still hovering over
             * the expanded thumb, we will also update the drag & drop action
             * of IconGroup on that.
             */
            float deleted_width = deleted_thumb.get_width () + group.get_width ();
            deleted_placeholder_thumb.expanded = true;
            deleted_placeholder_thumb.width += deleted_width;
            group.set_hovered_actor (deleted_placeholder_thumb);
        }

        public void reset_thumbs (int delay) {
            foreach (var child in get_children ()) {
                unowned WorkspaceInsertThumb thumb = child as WorkspaceInsertThumb;
                if (thumb != null) {
                    thumb.delay = delay;
                    thumb.destroy_all_children ();
                }
            }
        }

        void expanded_changed (ParamSpec param) {
            request_reposition (true);
        }

        /**
         * Calculates the width that will be occupied taking currently running animations
         * end states into account
         */
        public float calculate_total_width () {
            var scale = InternalUtils.get_ui_scaling_factor ();
            var spacing = SPACING * scale;
            var group_width = GROUP_WIDTH * scale;

            var width = 0.0f;
            foreach (var child in get_children ()) {
                if (child is WorkspaceInsertThumb) {
                    if (((WorkspaceInsertThumb) child).expanded)
                        width += group_width + spacing * 2;
                    else
                        width += spacing;
                } else
                    width += group_width;
            }

            width += spacing;

            return width;
        }

        void update_inserter_indices () {
            var current_index = 0;

            foreach (var child in get_children ()) {
                unowned WorkspaceInsertThumb thumb = child as WorkspaceInsertThumb;
                if (thumb != null) {
                    thumb.workspace_index = current_index++;
                }
            }
        }
    }
}
