namespace CoglFixes
{
	[CCode (cname = "cogl_texture_get_data")]
	public int texture_get_data (Cogl.Texture texture, Cogl.PixelFormat format, uint rowstride, [CCode (array_length = false)] uint8[] pixels);

	[CCode (cname = "cogl_material_set_user_program")]
	public void set_user_program (Cogl.Material material, Cogl.Handle program);

	[CCode (cname = "cogl_program_set_uniform_1f")]
	public void set_uniform_1f (Cogl.Program program, int uniform_no, float value);
	[CCode (cname = "cogl_program_set_uniform_1i")]
	public void set_uniform_1i (Cogl.Program program, int uniform_no, int value);

	[CCode (cname = "cogl_material_set_layer_wrap_mode")]
	public void material_set_layer_wrap_mode (Cogl.Material material, int layer_index, Cogl.MaterialWrapMode mode);

	[CCode (cname = "cogl_texture_get_gl_texture")]
	public void texture_get_gl_texture (Cogl.Handle texture, out uint gl_handle, out uint gl_target);
}
