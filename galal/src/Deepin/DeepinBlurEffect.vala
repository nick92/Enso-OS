//
//  Copyright (C) 2015 Deepin Technology Co., Ltd.
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

namespace Gala
{
	const string BLUR_SHADER_FRAG_H_CODE = """
// Fragment Shader horizontal
uniform sampler2D texture;
uniform int width;
uniform float radius;
uniform float bloom;

void main()
{
	float v;
	float pi = 3.141592653589793;
	float e_step = 1.0 / width;
	float rel_radius = radius;
	if (rel_radius < 0) rel_radius = 0;
	int steps = int(min(rel_radius * 0.7, sqrt(rel_radius) * pi));
	float r = rel_radius / steps;
	float t = bloom / (steps * 2 + 1);
	float x = cogl_tex_coord_in[0].x;
	float y = cogl_tex_coord_in[0].y;
	vec4 sum = texture2D(texture, vec2(x, y)) * t;
	int i;
	for(i = 1; i <= steps; i++){
		v = (cos(i / (steps + 1) / pi) + 1) * 0.5;
		sum += texture2D(texture, vec2(x + i * e_step * r, y)) * v * t;
		sum += texture2D(texture, vec2(x - i * e_step * r, y)) * v * t;
	}

    cogl_color_out = sum;
}
""";
	const string BLUR_SHADER_FRAG_V_CODE = """
// Fragment Shader vertical
uniform sampler2D texture;
uniform int height;
uniform float radius;
uniform float bloom;

void main()
{
	float v;
	float pi = 3.141592653589793;
	float e_step = 1.0 / height;
	float rel_radius = radius;
	if (rel_radius < 0) rel_radius = 0;
	int steps = int(min(rel_radius * 0.7, sqrt(rel_radius) * pi));
	float r = rel_radius / steps;
	float t = bloom / (steps * 2 + 1);
	float x = cogl_tex_coord_in[0].x;
	float y = cogl_tex_coord_in[0].y;
	vec4 sum = texture2D(texture, vec2(x, y)) * t;
	int i;
	for(i = 1; i <= steps; i++){
		v = (cos(i / (steps + 1) / pi) + 1) * 0.5;
		sum += texture2D(texture, vec2(x, y + i * e_step * r)) * v * t;
		sum += texture2D(texture, vec2(x, y - i * e_step * r)) * v * t;
	}

    cogl_color_out = sum;
}
""";

	public class DeepinBlurEffect : OffscreenEffect
	{
		public bool horizontal { get; construct; }
		public int width { get; construct; }
		public int height { get; construct; }
		public float radius { get; construct; }
		public float bloom { get; construct; }

		Cogl.Program program;

		public DeepinBlurEffect (bool horizontal, int width, int height, float radius, float bloom)
		{
			Object (horizontal: horizontal, width: width, height: height, radius: radius, bloom: bloom);
		}

		construct
		{
			program = new Cogl.Program ();

			var shader = new Cogl.Shader (Cogl.ShaderType.FRAGMENT);
			if (horizontal) {
				shader.source (BLUR_SHADER_FRAG_H_CODE);
			} else {
				shader.source (BLUR_SHADER_FRAG_V_CODE);
			}
			shader.compile ();
			program.attach_shader (shader);

			program.link ();

			int uniform_no;
			uniform_no = program.get_uniform_location ("texture");
			CoglFixes.set_uniform_1i (program, uniform_no, 0);
			uniform_no = program.get_uniform_location ("width");
			CoglFixes.set_uniform_1i (program, uniform_no, width);
			uniform_no = program.get_uniform_location ("height");
			CoglFixes.set_uniform_1i (program, uniform_no, height);
			uniform_no = program.get_uniform_location ("radius");
			CoglFixes.set_uniform_1f (program, uniform_no, radius);
			uniform_no = program.get_uniform_location ("bloom");
			CoglFixes.set_uniform_1f (program, uniform_no, bloom);
		}

		public static void setup (Actor actor, float radius, int repeat)
		{
			for (int i = 0; i < repeat; i++) {
				actor.add_effect (new DeepinBlurEffect (true, (int)actor.width, (int)actor.height, radius, 1.0f));
				actor.add_effect (new DeepinBlurEffect (false, (int)actor.width, (int)actor.height, radius, 1.0f));
			}
		}

		public void update_size (int new_width, int new_height)
		{
			int uniform_no;
			uniform_no = program.get_uniform_location ("width");
			CoglFixes.set_uniform_1i (program, uniform_no, new_width);
			uniform_no = program.get_uniform_location ("height");
			CoglFixes.set_uniform_1i (program, uniform_no, new_height);
		}

		public override void paint_target ()
		{
			var material = get_target ();
			CoglFixes.set_user_program (material, program);
			base.paint_target ();
		}
	}
}
