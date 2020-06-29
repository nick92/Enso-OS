namespace Cogl {
	[BooleanType]
	[CCode (cheader_filename = "cogl/cogl.h")]
	[SimpleType]
	public struct Bool : bool {
	}

	public struct Color {
		[Version (since = "1.4")]
		[CCode (cname="cogl_color_init_from_4f")]
		public Color.from_4f (float red, float green, float blue, float alpha);
		[Version (since = "1.4")]
		[CCode (cname="cogl_color_init_from_4fv")]
		public Color.from_4fv (float color_array);
		[Version (since = "1.4")]
		[CCode (cname="cogl_color_init_from_4ub")]
		public Color.from_4ub (uint8 red, uint8 green, uint8 blue, uint8 alpha);
		[Version (since = "1.16")]
		[CCode (cname="cogl_color_init_from_hsl")]
		public Color.from_hsl (float hue, float saturation, float luminance);
	}

	[Compact]
	public class Bitmap : Cogl.Handle {
	}

	[CCode (cheader_filename = "cogl/cogl.h", type_id = "cogl_quaternion_get_gtype ()", copy_function = "cogl_quaternion_copy", free_function = "cogl_quaternion_free")]
	[Compact]
	public class Quaternion {
	}

	[Compact]
	[CCode (cheader_filename = "cogl/cogl.h", type_id = "cogl_offscreen_get_gtype ()", ref_function = "cogl_offscreen_ref", unref_function = "cogl_offscreen_unref")]
	public class Offscreen : Cogl.Handle {
	}

	[Compact]
	[CCode (cname = "CoglHandle", cheader_filename = "cogl/cogl.h", type_id = "cogl_handle_get_gtype ()", ref_function = "cogl_vertex_buffer_ref", unref_function = "cogl_vertex_buffer_unref")]
	public class VertexBuffer : Cogl.Handle {
	}

	[Compact]
	[CCode (cname = "CoglHandle", cheader_filename = "cogl/cogl.h", type_id = "cogl_handle_get_gtype ()", ref_function = "cogl_shader_ref", unref_function = "cogl_shader_unref")]
	public class Shader : Cogl.Handle {
	}

	[Compact]
	[CCode (cname = "CoglHandle", cheader_filename = "cogl/cogl.h", type_id = "cogl_handle_get_gtype ()", ref_function = "cogl_program_ref", unref_function = "cogl_program_unref")]
	public class Program : Cogl.Handle {
	}

	[Compact]
	[CCode (cheader_filename = "cogl/cogl.h", type_id = "cogl_handle_get_gtype ()", ref_function = "cogl_handle_ref", unref_function = "cogl_handle_unref")]
	public class Handle {
		[CCode (cheader_filename = "cogl/cogl.h", cname="cogl_is_bitmap")]
		[Version (since = "1.0")]
		public Cogl.Bool is_bitmap ();
		[CCode (cheader_filename = "cogl/cogl.h", cname="cogl_is_material")]
		[Version (deprecated = true, deprecated_since = "1.16")]
		public Cogl.Bool is_material ();
		[CCode (cheader_filename = "cogl/cogl.h", cname="cogl_is_offscreen")]
		public Cogl.Bool is_offscreen ();
		[CCode (cheader_filename = "cogl/cogl.h", cname="cogl_is_program")]
		[Version (deprecated = true, deprecated_since = "1.16")]
		public Cogl.Bool is_program (Cogl.Handle handle);
		[CCode (cheader_filename = "cogl/cogl.h", cname="cogl_is_shader")]
		[Version (deprecated = true, deprecated_since = "1.16")]
		public Cogl.Bool is_shader ();
		[CCode (cheader_filename = "cogl/cogl.h", cname="cogl_is_texture")]
		public Cogl.Bool is_texture ();
		[CCode (cheader_filename = "cogl/cogl.h", cname="cogl_is_vertex_buffer")]
		[Version (deprecated = true, deprecated_since = "1.16", since = "1.0")]
		public Cogl.Bool is_vertex_buffer ();
		[CCode (cheader_filename = "cogl/cogl.h", cname="cogl_is_vertex_buffer_indices")]
		[Version (deprecated = true, deprecated_since = "1.16", since = "1.4")]
		public Cogl.Bool is_vertex_buffer_indices ();
	}

}
