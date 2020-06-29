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

namespace Gala.Plugins.PIP {
    public class ShadowEffect : Effect {
        private class Shadow {
            public int users;
            public Cogl.Texture texture;

            public Shadow (Cogl.Texture _texture) {
                texture = _texture;
                users = 1;
            }
        }

        // the sizes of the textures often repeat, especially for the background actor
        // so we keep a cache to avoid creating the same texture all over again.
        static Gee.HashMap<string,Shadow> shadow_cache;

        static construct {
            shadow_cache = new Gee.HashMap<string,Shadow> ();
        }

        public int shadow_size { get; construct; }
        public int shadow_spread { get; construct; }

        public float scale_factor { get; set; default = 1; }
        public uint8 shadow_opacity { get; set; default = 255; }

#if HAS_MUTTER336
        Cogl.Pipeline pipeline;
#else
        Cogl.Material material;
#endif

        string? current_key = null;

        public ShadowEffect (int shadow_size, int shadow_spread) {
            Object (shadow_size: shadow_size, shadow_spread: shadow_spread);
        }

        construct {
#if HAS_MUTTER336
            pipeline = new Cogl.Pipeline (Clutter.get_default_backend ().get_cogl_context ());
#else
            material = new Cogl.Material ();
#endif

        }

        ~ShadowEffect () {
            if (current_key != null)
                decrement_shadow_users (current_key);
        }

#if HAS_MUTTER336
        Cogl.Texture? get_shadow (Cogl.Context context, int width, int height, int shadow_size, int shadow_spread) {
#else
        Cogl.Texture? get_shadow (int width, int height, int shadow_size, int shadow_spread) {
#endif
            var old_key = current_key;

            current_key = "%ix%i:%i:%i".printf (width, height, shadow_size, shadow_spread);
            if (old_key == current_key)
                return null;

            if (old_key != null)
                decrement_shadow_users (old_key);

            Shadow? shadow = null;
            if ((shadow = shadow_cache.@get (current_key)) != null) {
                shadow.users++;
                return shadow.texture;
            }

            // fill a new texture for this size
            var buffer = new Granite.Drawing.BufferSurface (width, height);
            buffer.context.rectangle (shadow_size - shadow_spread, shadow_size - shadow_spread,
                width - shadow_size * 2 + shadow_spread * 2, height - shadow_size * 2 + shadow_spread * 2);
            buffer.context.set_source_rgba (0, 0, 0, 0.7);
            buffer.context.fill ();

            buffer.exponential_blur (shadow_size / 2);

            var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height);
            var cr = new Cairo.Context (surface);

            cr.set_source_surface (buffer.surface, 0, 0);
            cr.paint ();

#if HAS_MUTTER336
            var texture = new Cogl.Texture2D.from_data (context, width, height, Cogl.PixelFormat.BGRA_8888_PRE,
                surface.get_stride (), surface.get_data ());
#else
            var texture = new Cogl.Texture.from_data (width, height, 0, Cogl.PixelFormat.BGRA_8888_PRE,
                Cogl.PixelFormat.ANY, surface.get_stride (), surface.get_data ());
#endif

            shadow_cache.@set (current_key, new Shadow (texture));

            return texture;
        }

        void decrement_shadow_users (string key) {
            var shadow = shadow_cache.@get (key);

            if (shadow == null)
                return;

            if (--shadow.users == 0)
                shadow_cache.unset (key);
        }

#if HAS_MUTTER336
        public override void paint (Clutter.PaintContext context, EffectPaintFlags flags) {
            var bounding_box = get_bounding_box ();

            var shadow = get_shadow (context.get_framebuffer ().get_context (), (int) (bounding_box.x2 - bounding_box.x1),
            (int) (bounding_box.y2 - bounding_box.y1), shadow_size, shadow_spread);

            if (shadow != null)
                pipeline.set_layer_texture (0, shadow);

            var opacity = actor.get_paint_opacity () * shadow_opacity / 255;
            var alpha = Cogl.Color.from_4ub (255, 255, 255, opacity);
            alpha.premultiply ();

            pipeline.set_color (alpha);

            context.get_framebuffer ().draw_rectangle (pipeline, bounding_box.x1, bounding_box.y1, bounding_box.x2, bounding_box.y2);

            actor.continue_paint (context);
        }
#else
        public override void paint (EffectPaintFlags flags) {
            var bounding_box = get_bounding_box ();
            var shadow = get_shadow ((int) (bounding_box.x2 - bounding_box.x1), (int) (bounding_box.y2 - bounding_box.y1),
                shadow_size, shadow_spread);

            if (shadow != null)
                material.set_layer (0, shadow);

            var opacity = actor.get_paint_opacity () * shadow_opacity / 255;
            var alpha = Cogl.Color.from_4ub (255, 255, 255, opacity);
            alpha.premultiply ();

            material.set_color (alpha);

            Cogl.set_source (material);
            Cogl.rectangle (bounding_box.x1, bounding_box.y1, bounding_box.x2, bounding_box.y2);

            actor.continue_paint ();
        }
#endif

        public virtual ActorBox get_bounding_box () {
            var size = shadow_size * scale_factor;
            var bounding_box = ActorBox ();

            bounding_box.set_origin (-size, -size);
            bounding_box.set_size (actor.width + size * 2, actor.height + size * 2);

            return bounding_box;
        }
    }
}
