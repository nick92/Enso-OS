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

	[CCode (cname = "cogl_get_source")]
	public void *get_source ();

	[CCode (cname = "cogl_pop_source")]
	public void pop_source ();
	[CCode (cname = "cogl_push_source")]
	public void push_source (void *material_or_pipeline);
}
