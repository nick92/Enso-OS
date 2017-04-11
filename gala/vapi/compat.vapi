namespace Cogl
{
	[CCode (cheader_filename = "cogl/cogl.h")]
	public class Context : Cogl.Handle {
	}

	[CCode (cname = "cogl_bitmap_new_for_data")]
	public static Cogl.Bitmap bitmap_new_for_data (Cogl.Context Context, int width, int height, Cogl.PixelFormat format, int rowstride, [CCode (array_length = false)] uchar[] data);

	[CCode (cname = "cogl_get_draw_framebuffer")]
	public static unowned Cogl.Framebuffer get_draw_framebuffer ();

	[CCode (cname = "cogl_framebuffer_read_pixels_into_bitmap")]
	public static Cogl.Bool framebuffer_read_pixels_into_bitmap (Cogl.Framebuffer framebuffer, int x, int y, Cogl.ReadPixelsFlags source, Cogl.Bitmap bitmap);
}

namespace Clutter
{
	[CCode (cname = "clutter_backend_get_cogl_context")]
	public static unowned Cogl.Context backend_get_cogl_context (Clutter.Backend backend);
}
