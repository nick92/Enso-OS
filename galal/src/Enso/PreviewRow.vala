
using Meta;
using Gala;
using Clutter;

namespace Gala
{
    public class PreviewRow : Clutter.Actor {
        private const int SPACING = 24;
        public float max_width { get; construct; }

        public PreviewRow (float max_width) {
            Object (max_width: max_width);
            background_color = { 255, 255, 0, 100 };
        }

        public bool add_window_actor (WindowActorClone window_actor)
        {
            float actor_width = window_actor.width;
            float avail_width = max_width - get_real_width ();
            if (actor_width > avail_width + SPACING) {
                return false;
            }

            add_child (window_actor);
            reallocate ();
            return true;
        }

        private float get_real_width ()
        {
            float width = 0;
            uint child_count = get_children ().length ();
            uint spacing;
            if (child_count > 1) {
                spacing = (child_count - 1) * SPACING;
            } else {
                spacing = 0;
            }

            get_children ().@foreach ((child) => {
                width += child.width;
            });

            return width + spacing;
        }

        private void reallocate ()
        {
            float remaining = (max_width - get_real_width ()) / 2;
            float offset = 0;

            var children = get_children ();
            uint child_count = children.length ();
            for (int i = 0; i < child_count; i++) {
                int spacing;
                if (i != 0) {
                    spacing = SPACING;
                } else {
                    spacing = 0;
                }

                var child = children.nth_data (i);
                child.x = remaining + offset + spacing;
                offset += child.width + spacing;
            }
        }
    }
}
