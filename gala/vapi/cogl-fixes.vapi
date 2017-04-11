namespace CoglFixes
{
	[CCode (cname = "cogl_texture_get_data")]
	public int texture_get_data (Cogl.Texture texture, Cogl.PixelFormat format, uint rowstride, [CCode (array_length = false)] uint8[] pixels);
}

