
using Meta;
using Gala;
using Clutter;

namespace Gala
{
    public class PreviewPage : Clutter.Actor
    {
        const int SPACING = 12;
        const int PADDING = 24;
        const int MIN_OFFSET = 32;

        public Screen screen { get; construct; }

        public WindowActorClone? current { get; set; }

        public Clutter.Actor container;

        public PreviewPage (Screen screen) {
            Object (screen: screen);
        }

        construct {
            var monitor = screen.get_current_monitor ();
            var geom = screen.get_monitor_geometry (monitor);
            width = geom.width - MIN_OFFSET * 2;
            height = geom.height - MIN_OFFSET * 2;
            x = MIN_OFFSET;
            y = MIN_OFFSET;

            container = new Clutter.Actor ();
            container.set_size (width, -1);
            add_child (container);
        }

        public bool add_window_actor (WindowActorClone window_actor) {
            container.add_child (window_actor);
            return true;
        }

        public bool next (bool backward) {
            if (!backward) {
                current = current.get_next_sibling () as WindowActorClone;
                if (current == null) {
                    current = container.get_first_child () as WindowActorClone;
                }

            } else {
                current = current.get_previous_sibling () as WindowActorClone;
                if (current == null) {
                    current = container.get_last_child () as WindowActorClone;
                }
            }

            return current != null;
        }

        public void reallocate ()
        {
            var children = container.get_children ();
            uint child_count = children.length ();

            float current_height = 0;
            float current_width = 0;

            float max_width = width;

            var row_children = new Gee.ArrayList<Clutter.Actor> ();

            for (int i = 0; i < child_count; i++) {
                var child = children.nth_data (i);
                if (child.width > max_width - current_width) {
                    float max_row_height = allocate_align_row (row_children, max_width, current_height);

                    current_height += max_row_height + SPACING;
                    row_children.clear ();
                    current_width = 0;
                }

                current_width += child.width;
                if (row_children.size > 0) {
                    current_width += SPACING;
                }

                row_children.add (child);
            }

            if (row_children.size > 0) {
                allocate_align_row (row_children, max_width, current_height);
            }

            container.x = width / 2 - container.width / 2;
            container.y = height / 2 - container.height / 2;
        }

        private float allocate_align_row (Gee.ArrayList<Clutter.Actor> actors, float max_width, float y)
        {
            float real_width = 0;
            foreach (var actor in actors) {
                real_width += actor.width;
            }

            int spacing;
            if (actors.size > 1) {
                spacing = (actors.size - 1) * SPACING;
            } else {
                spacing = 0;
            }

            real_width += spacing;

            float max_height = 0;

            float row_offset = (max_width - real_width) / 2;
            float actor_offset = 0;
            for (int i = 0; i < actors.size; i++) {
                var actor = actors[i];
                int actor_spacing;
                if (i != 0) {
                    actor_spacing = SPACING;
                } else {
                    actor_spacing = 0;
                }

                actor.x = row_offset + actor_offset + actor_spacing;
                actor.y = y;
                actor_offset += actor.width + actor_spacing;
                max_height = float.max (max_height, actor.height);
            }

            return max_height;
        }
    }
}
