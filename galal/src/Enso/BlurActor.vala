//
//  Copyright (C) 2018 Adam Bieńkowski
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

// Original blur algorithm and shaders by Marius Bjørge,
// available on https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-20-66/siggraph2015_2D00_mmg_2D00_marius_2D00_notes.pdf

// Reference implementation by Alex Nemeth for KDE: https://phabricator.kde.org/D9848

namespace Gala
{
    /**
     * Contains the offscreen framebuffer and the target texture that's
     * attached to it.
     */
    class FramebufferContainer
    {
        public Cogl.Offscreen fbo;
        public Cogl.Texture texture;
        public FramebufferContainer (Cogl.Texture texture)
        {
            this.texture = texture;
            fbo = new Cogl.Offscreen.to_texture (texture);
        }
    }

    struct Geometry
    {
        float x1;
        float y1;
        float x2;
        float y2;
    }

    /**
     * Workaround for Vala not supporting static signals.
     */
    class HandleNotifier
    {
        public signal void updated ();
    }

    const string DOWNSAMPLE_FRAG_SHADER = """
        uniform sampler2D tex;
        uniform float half_width;
        uniform float half_height;
        uniform float offset;

        void main () {
            vec2 uv = cogl_tex_coord0_in.xy;
            vec2 halfpixel = vec2(half_width, half_height);

            vec4 sum = texture2D (tex, uv) * 4.0;
            sum += texture2D (tex, uv - halfpixel.xy * offset);
            sum += texture2D (tex, uv + halfpixel.xy * offset);
            sum += texture2D (tex, uv + vec2(halfpixel.x, -halfpixel.y) * offset);
            sum += texture2D (tex, uv - vec2(halfpixel.x, -halfpixel.y) * offset);
            cogl_color_out = sum / 8.0;
        }
    """;

    const string UPSAMPLE_FRAG_SHADER = """
        uniform sampler2D tex;
        uniform float half_width;
        uniform float half_height;
        uniform float offset;
        uniform float saturation;
		uniform float brightness;

        vec3 saturate (vec3 rgb, float adjustment) {
            const vec3 W = vec3(0.2125, 0.7154, 0.0721);
            vec3 intensity = vec3(dot(rgb, W));
            return mix (intensity, rgb, adjustment);
        }

        void main () {
            vec2 uv = cogl_tex_coord0_in.xy;
            vec2 halfpixel = vec2(half_width, half_height);

            vec4 sum = texture2D (tex, uv + vec2(-halfpixel.x * 2.0, 0.0) * offset);
            sum += texture2D (tex, uv + vec2(-halfpixel.x, halfpixel.y) * offset) * 2.0;
            sum += texture2D (tex, uv + vec2(0.0, halfpixel.y * 2.0) * offset);
            sum += texture2D (tex, uv + vec2(halfpixel.x, halfpixel.y) * offset) * 2.0;
            sum += texture2D (tex, uv + vec2(halfpixel.x * 2.0, 0.0) * offset);
            sum += texture2D (tex, uv + vec2(halfpixel.x, -halfpixel.y) * offset) * 2.0;
            sum += texture2D (tex, uv + vec2(0.0, -halfpixel.y * 2.0) * offset);
            sum += texture2D (tex, uv + vec2(-halfpixel.x, -halfpixel.y) * offset) * 2.0;
            sum /= 12.0;

            vec3 mixed = saturate (sum.rgb, saturation) + vec3 (brightness, brightness, brightness);
            cogl_color_out = vec4 (mixed, sum.a) * cogl_color_in;
        }
    """;

    const string COPYSAMPLE_FRAG_SHADER = """
        uniform sampler2D tex;
        uniform float tex_x1;
        uniform float tex_y1;
        uniform float tex_x2;
        uniform float tex_y2;

        void main () {
            vec2 uv = cogl_tex_coord0_in.xy;
            vec2 min = vec2(tex_x1, tex_y1);
            vec2 max = vec2(tex_x2, tex_y2);
            cogl_color_out = texture2D(tex, clamp (uv, min, max));
        }
    """;

    public class BlurActor : Clutter.Actor
    {
        const int DOCK_SHRINK_AREA = 2;
        const uint GL_TEXTURE_2D = 0x0DE1;
        const uint GL_MAX_TEXTURE_SIZE = 0x0D33;

        static int down_width_location;
        static int down_height_location;

        static int up_width_location;
        static int up_height_location;

        static Cogl.Program down_program;
        static Cogl.Program up_program;
        static Cogl.Program copysample_program;

        static Cogl.Material down_material;
        static Cogl.Material up_material;
        static Cogl.Material copysample_material;

        static Cogl.VertexBuffer vbo;

        static int down_offset_location;
        static int up_offset_location;

        static int saturation_location;
        static int brightness_location;

        static int copysample_tex_x_location;
        static int copysample_tex_y_location;
        static int copysample_tex_width_location;
        static int copysample_tex_height_location;

        static float[] pos_indicies;
        static float[] tex_indicies;

        static GlCopyTexSubFunc? copy_tex_sub_image;
        static GlBindTextureFunc? bind_texture;

        static Cogl.Texture copysample_texture;
        static Gee.ArrayList<FramebufferContainer> textures;

        static HandleNotifier handle_notifier;
        static uint handle;
        static uint copysample_handle;

        static int iterations;
        static int expand_size;

        static float stage_width;
        static float stage_height;

        static ulong allocation_watch_id = 0U;

        static unowned Clutter.Actor ui_group;

        delegate void GlCopyTexSubFunc (uint target, int level,
                                        int xoff, int yoff,
                                        int x, int y,
                                        int width, int height);
        delegate void GlBindTextureFunc (uint target, uint texture);
        delegate void GlGetIntegervFunc (uint pname, out int params);

        public signal void clip_updated ();

        public Meta.WindowActor? window_actor { get; construct; }
        public Meta.Rectangle blur_clip_rect { get; set; }

        Meta.Window? window;

        Meta.Rectangle actor_rect;
        Meta.Rectangle tex_rect;

        bool is_dock = false;
        uint current_handle;

        public static void init (int _iterations, float offset, int _expand_size, Clutter.Actor _ui_group)
        {
            iterations = _iterations;
            ui_group = _ui_group;
            expand_size = _expand_size;

            handle_notifier = new HandleNotifier ();

            Cogl.Shader fragment;
            int tex_location;
            if (down_program == null) {
                fragment = new Cogl.Shader (Cogl.ShaderType.FRAGMENT);
                fragment.source (DOWNSAMPLE_FRAG_SHADER);

                down_program = new Cogl.Program ();
                down_program.attach_shader (fragment);
                down_program.link ();

                tex_location = down_program.get_uniform_location ("tex");
                down_width_location = down_program.get_uniform_location ("half_width");
                down_height_location = down_program.get_uniform_location ("half_height");
                down_offset_location = down_program.get_uniform_location ("offset");

                CoglFixes.set_uniform_1i (down_program, tex_location, 0);
            }

            if (up_program == null) {
                fragment = new Cogl.Shader (Cogl.ShaderType.FRAGMENT);
                fragment.source (UPSAMPLE_FRAG_SHADER);

                up_program = new Cogl.Program ();
                up_program.attach_shader (fragment);
                up_program.link ();

                tex_location = up_program.get_uniform_location ("tex");
                up_width_location = up_program.get_uniform_location ("half_width");
                up_height_location = up_program.get_uniform_location ("half_height");
                up_offset_location = up_program.get_uniform_location ("offset");
                saturation_location = up_program.get_uniform_location ("saturation");
                brightness_location = up_program.get_uniform_location ("brightness");
                up_offset_location = up_program.get_uniform_location ("offset");

                CoglFixes.set_uniform_1i (up_program, tex_location, 0);
                CoglFixes.set_uniform_1f (up_program, saturation_location, 1.0f);
                CoglFixes.set_uniform_1f (up_program, brightness_location, 0.0f);
            }

            if (copysample_program == null) {
                fragment = new Cogl.Shader (Cogl.ShaderType.FRAGMENT);
                fragment.source (COPYSAMPLE_FRAG_SHADER);

                copysample_program = new Cogl.Program ();
                copysample_program.attach_shader (fragment);
                copysample_program.link ();

                tex_location = copysample_program.get_uniform_location ("tex");
                copysample_tex_x_location = copysample_program.get_uniform_location ("tex_x1");
                copysample_tex_y_location = copysample_program.get_uniform_location ("tex_y1");
                copysample_tex_width_location = copysample_program.get_uniform_location ("tex_x2");
                copysample_tex_height_location = copysample_program.get_uniform_location ("tex_y2");

                CoglFixes.set_uniform_1i (copysample_program, tex_location, 0);
            }

            if (down_material == null) {
                down_material = new Cogl.Material ();
                down_material.set_layer_filters (0, Cogl.MaterialFilter.LINEAR, Cogl.MaterialFilter.LINEAR);
                CoglFixes.material_set_layer_wrap_mode (down_material, 0, Cogl.MaterialWrapMode.CLAMP_TO_EDGE);
                CoglFixes.set_user_program (down_material, down_program);
            }

            if (up_material == null) {
                up_material = new Cogl.Material ();
                up_material.set_layer_filters (0, Cogl.MaterialFilter.LINEAR, Cogl.MaterialFilter.LINEAR);
                CoglFixes.material_set_layer_wrap_mode (up_material, 0, Cogl.MaterialWrapMode.CLAMP_TO_EDGE);
                CoglFixes.set_user_program (up_material, up_program);
            }

            if (copysample_material == null) {
                copysample_material = new Cogl.Material ();
                copysample_material.set_layer_filters (0, Cogl.MaterialFilter.LINEAR, Cogl.MaterialFilter.LINEAR);
                CoglFixes.set_user_program (copysample_material, copysample_program);
            }

            if (vbo == null) {
                vbo = new Cogl.VertexBuffer (iterations * 2 * 6);
            }

            CoglFixes.set_uniform_1f (down_program, down_offset_location, offset);
            CoglFixes.set_uniform_1f (up_program, up_offset_location, offset);

            copy_tex_sub_image = (GlCopyTexSubFunc)Cogl.get_proc_address ("glCopyTexSubImage2D");
            bind_texture = (GlBindTextureFunc)Cogl.get_proc_address ("glBindTexture");

            if (textures == null) {
                textures = new Gee.ArrayList<FramebufferContainer> ();
            }

            if (allocation_watch_id == 0U) {
                var stage = ui_group.get_stage ();
                allocation_watch_id = stage.notify["allocation"].connect (() => init_fbo_textures ());
            }

            init_fbo_textures ();
        }

        public static void deinit ()
        {
            if (!is_initted ()) {
                return;
            }

            if (allocation_watch_id != 0U) {
                ui_group.get_stage ().disconnect (allocation_watch_id);
                allocation_watch_id = 0U;
            }

            textures.clear ();
        }

        public static bool is_initted ()
        {
            return textures != null && textures.size > 0;
        }

        public static bool get_enabled_by_default ()
        {
            unowned RendererInfo info = RendererInfo.get_default ();
            if (info.vendor == Vendor.VIRTUAL) {
                return true;
            }

            if (info.vendor == Vendor.INTEL && info.intel_chipset < IntelChipset.SandyBridge) {
                return false;
            }

            return true;
        }

        public static bool get_supported (WindowManager wm)
        {
            var gl_get_integer = (GlGetIntegervFunc) Cogl.get_proc_address ("glGetIntegerv");

            int max_texture_size;
            gl_get_integer (GL_MAX_TEXTURE_SIZE, out max_texture_size);

            int screen_width, screen_height;
            wm.get_screen ().get_size (out screen_width, out screen_height);

            if (screen_width > max_texture_size || screen_height > max_texture_size) {
                return false;
            }

            return Cogl.features_available (Cogl.FeatureFlags.OFFSCREEN |
                                            Cogl.FeatureFlags.SHADERS_GLSL |
                                            Cogl.FeatureFlags.TEXTURE_RECTANGLE |
                                            Cogl.FeatureFlags.TEXTURE_NPOT);
        }

        construct
        {
            if (window_actor != null) {
                window = window_actor.get_meta_window ();
                window.notify["window-type"].connect (update_window_type);
            }

            handle_notifier.updated.connect (update_current_handle);
            update_window_type ();
        }

        public BlurActor (Meta.WindowActor? window_actor)
        {
            Object (window_actor: window_actor);
        }

        static void init_fbo_textures ()
        {
            textures.clear ();

            var stage = ui_group.get_stage ();
            stage.get_size (out stage_width, out stage_height);

            copysample_texture = new Cogl.Texture.with_size ((int)stage_width, (int)stage_height,
                    Cogl.TextureFlags.NO_AUTO_MIPMAP, Cogl.PixelFormat.RGBA_8888);
            copysample_material.set_layer (0, copysample_texture);

            CoglFixes.texture_get_gl_texture ((Cogl.Handle)copysample_texture, out copysample_handle, null);

            for (int i = 0; i <= iterations; i++) {
                int downscale = 1 << i;

                uint width = (int)(stage_width / downscale);
                uint height = (int)(stage_height / downscale);

                var texture = new Cogl.Texture.with_size (width, height,
                    Cogl.TextureFlags.NO_AUTO_MIPMAP, Cogl.PixelFormat.RGBA_8888);
                textures.add (new FramebufferContainer (texture));
            }

            CoglFixes.texture_get_gl_texture ((Cogl.Handle)textures[0].texture, out handle, null);

            handle_notifier.updated ();
        }

        public override void allocate (Clutter.ActorBox box, Clutter.AllocationFlags flags)
        {
            if (window != null) {
                float x, y;
                window_actor.get_position (out x, out y);

                var rect = window.get_frame_rect ();
                float width = blur_clip_rect.width > 0 ? blur_clip_rect.width : rect.width;
                float height = blur_clip_rect.height > 0 ? blur_clip_rect.height : rect.height;

                width = width.clamp (1, width - blur_clip_rect.x);
                height = height.clamp (1, height - blur_clip_rect.y);

                box.set_size (width, height);
                box.set_origin (rect.x - x + blur_clip_rect.x, rect.y - y + blur_clip_rect.y);
            }

            base.allocate (box, flags);
        }

        public override void paint ()
        {
            if (!is_visible () || textures.size == 0) {
                return;
            }

            ui_group.get_stage ().ensure_viewport ();

            float width, height, x, y;
            get_size (out width, out height);
            get_transformed_position (out x, out y);

            float transformed_width, transformed_height;
            get_transformed_size (out transformed_width, out transformed_height);

            double sx, sy;
            ui_group.get_scale (out sx, out sy);

            actor_rect = {
                (int)x, (int)y,
                (int)(width * (float)sx), (int)(height * (float)sy)
            };

            float cx = float.max (0, x - expand_size);
            float cy = float.max (0, y - expand_size);

            int tex_width = int.min ((actor_rect.width + expand_size * 2), (int)(stage_width - cx));
            int tex_height = int.min ((actor_rect.height + expand_size * 2), (int)(stage_height - cy));

            int tex_x = int.min ((int)cx, (int)stage_width);
            int tex_y = int.min ((int)(stage_height - cy - tex_height), (int)stage_height);

            tex_rect = {
                tex_x, tex_y,
                tex_width, tex_height
            };

            upload_geometry ();

            copy_target_texture ();

            downsample ();
            upsample ();

            CoglFixes.set_uniform_1f (up_program, up_width_location, 0.5f / stage_width);
            CoglFixes.set_uniform_1f (up_program, up_height_location, 0.5f / stage_height);

            uint8 paint_opacity = get_paint_opacity ();

            var texture = textures[1].texture;
            float source_width = (float)texture.get_width ();
            float source_height = (float)texture.get_height ();

            up_material.set_layer (0, texture);
            up_material.set_color4ub (paint_opacity, paint_opacity, paint_opacity, paint_opacity);

            CoglFixes.set_uniform_1f (up_program, saturation_location, 1.4f);
            CoglFixes.set_uniform_1f (up_program, brightness_location, 1.3f);

            Cogl.rectangle_with_texture_coords (
                0, 0, width, height,
                (x / 2) / source_width, (y / 2) / source_height,
                ((x + transformed_width) / 2) / source_width,
                ((y + transformed_height) / 2) / source_height);

            CoglFixes.set_uniform_1f (up_program, saturation_location, 1.0f);
            CoglFixes.set_uniform_1f (up_program, brightness_location, 0.0f);

            up_material.set_color4ub (255, 255, 255, 255);
        }

        void update_window_type ()
        {
            is_dock = window != null && window.get_window_type () == Meta.WindowType.DOCK;
            update_current_handle ();
        }

        inline void update_current_handle ()
        {
            current_handle = is_dock ? copysample_handle : handle;
        }

        void copy_target_texture ()
        {
            Cogl.begin_gl ();
            bind_texture (GL_TEXTURE_2D, current_handle);

            copy_tex_sub_image (GL_TEXTURE_2D, 0, tex_rect.x, tex_rect.y,
                tex_rect.x, tex_rect.y, (int)tex_rect.width, (int)tex_rect.height);

            bind_texture (GL_TEXTURE_2D, 1);
            Cogl.end_gl ();

            if (is_dock) {
                float x1 = (actor_rect.x + DOCK_SHRINK_AREA) / stage_width;
                float x2 = (actor_rect.x + actor_rect.width - DOCK_SHRINK_AREA) / stage_width;

                // Flip texture coordinates due to Cogl bug
                float y1 = (stage_height - (actor_rect.y + actor_rect.height) + DOCK_SHRINK_AREA) / stage_height;
                float y2 = (stage_height - actor_rect.y  - DOCK_SHRINK_AREA) / stage_height;

                CoglFixes.set_uniform_1f (copysample_program, copysample_tex_x_location, x1);
                CoglFixes.set_uniform_1f (copysample_program, copysample_tex_y_location, y1);
                CoglFixes.set_uniform_1f (copysample_program, copysample_tex_width_location, x2);
                CoglFixes.set_uniform_1f (copysample_program, copysample_tex_height_location, y2);

                unowned Cogl.Framebuffer target = (Cogl.Framebuffer)textures.first ().fbo;

                Cogl.set_source (copysample_material);
                Cogl.push_framebuffer (target);
                Cogl.push_matrix ();
                Cogl.scale (1, -1, 1);
                vbo.draw (Cogl.VerticesMode.TRIANGLES, 0, 6);
                Cogl.pop_matrix ();
                Cogl.pop_framebuffer ();
            }
        }

        static inline float map_coord_to_gl (float target_size, float pos)
        {
            return 2.0f / target_size * pos - 1.0f;
        }

        void upload_region (FramebufferContainer source, FramebufferContainer dest, int iteration, Geometry region, bool flip)
        {
            var target_texture = dest.texture;
            var source_texture = source.texture;

            float target_width = (float)target_texture.get_width ();
            float target_height = (float)target_texture.get_height ();
            float source_width = (float)source_texture.get_width ();
            float source_height = (float)source_texture.get_height ();

            int prev_division_ratio = 1 << (iteration - 1);
            int division_ratio = 1 << iteration;

            float x1 = map_coord_to_gl (target_width, region.x1 / division_ratio);
            float x2 = map_coord_to_gl (target_width, region.x2 / division_ratio);

            float tx1 = region.x1 / prev_division_ratio / source_width;
            float tx2 = region.x2 / prev_division_ratio / source_width;

            /**
             * Cogl bug: rendering to FBO flips the texture vertically
             * so we have to account for that and flip texture coordinates
             * every second texture draw.
             */
            float y1, y2, ty1, ty2;
            if (flip) {
                y1 = map_coord_to_gl (target_height, target_height - region.y2 / division_ratio);
                y2 = map_coord_to_gl (target_height, target_height - region.y1 / division_ratio);

                ty1 = (source_height - region.y2 / prev_division_ratio) / source_height;
                ty2 = (source_height - region.y1 / prev_division_ratio) / source_height;
            } else {
                y1 = map_coord_to_gl (target_height, region.y1 / division_ratio);
                y2 = map_coord_to_gl (target_height, region.y2 / division_ratio);

                ty1 = region.y1 / prev_division_ratio / source_height;
                ty2 = region.y2 / prev_division_ratio / source_height;
            }

            /**
             * First triangle for screen coordinates.
             */
            pos_indicies += x1; pos_indicies += y1;
            pos_indicies += x1; pos_indicies += y2;
            pos_indicies += x2; pos_indicies += y1;

            /**
             * Second triangle for screen coordinates.
             */
            pos_indicies += x2; pos_indicies += y1;
            pos_indicies += x1; pos_indicies += y2;
            pos_indicies += x2; pos_indicies += y2;

            /**
             * First triangle for texture coordinates.
             */
            tex_indicies += tx1; tex_indicies += ty1;
            tex_indicies += tx1; tex_indicies += ty2;
            tex_indicies += tx2; tex_indicies += ty1;

            /**
             * Second triangle for texture coordinates.
             */
            tex_indicies += tx2; tex_indicies += ty1;
            tex_indicies += tx1; tex_indicies += ty2;
            tex_indicies += tx2; tex_indicies += ty2;
        }

        void upload_geometry ()
        {
            pos_indicies = {};
            tex_indicies = {};

            Geometry blur_region = { tex_rect.x, tex_rect.y, tex_rect.x + tex_rect.width, tex_rect.y + tex_rect.height };
            for (int i = 1; i <= iterations; i++) {
                var source = textures[i - 1];
                var dest = textures[i];

                upload_region (source, dest, i, blur_region, i % 2 == 0);
            }

            for (int i = 1; i <= iterations; i++) {
                var source = textures[i - 1];
                var dest = textures[i];

                upload_region (source, dest, i, blur_region, i % 2 != 0);
            }

            vbo.add ("gl_Vertex", 2, Cogl.AttributeType.FLOAT, false, 0, pos_indicies);
            vbo.add ("gl_MultiTexCoord0", 2, Cogl.AttributeType.FLOAT, false, 0, tex_indicies);
        }

        void downsample ()
        {
            Cogl.set_source (down_material);
            for (int i = 1; i <= iterations; i++) {
                var source_cont = textures[i - 1];
                var dest_cont = textures[i];

                render_to_fbo (source_cont, dest_cont, down_material,
                            down_program, down_width_location, down_height_location, i - 1);
            }
        }

        void upsample ()
        {
            Cogl.set_source (up_material);
            for (int i = iterations - 1; i >= 1; i--) {
                var source_cont = textures[i + 1];
                var dest_cont = textures[i];

                render_to_fbo (source_cont, dest_cont, up_material,
                            up_program, up_width_location, up_height_location, iterations + i);

            }
        }

        void render_to_fbo (FramebufferContainer source, FramebufferContainer dest, Cogl.Material material,
                            Cogl.Program program, int width_location, int height_location, int i)
        {
            material.set_layer (0, source.texture);

            var target_texture = dest.texture;
            CoglFixes.set_uniform_1f (program, width_location, 0.5f / target_texture.get_width ());
            CoglFixes.set_uniform_1f (program, height_location, 0.5f / target_texture.get_height ());

            Cogl.push_framebuffer ((Cogl.Framebuffer)dest.fbo);
            vbo.draw (Cogl.VerticesMode.TRIANGLES, i * 6, 6);
            Cogl.pop_framebuffer ();
        }
    }
}
