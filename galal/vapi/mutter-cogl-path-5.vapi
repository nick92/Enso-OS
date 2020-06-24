[CCode (gir_namespace = "CoglPath", gir_version = "5")]
namespace Cogl {
	[CCode (cheader_filename = "cogl-path/cogl-path.h", copy_function = "cogl_path_copy", ref_function = "cogl_object_ref", unref_function = "cogl_object_unref", type_id = "cogl_path_get_gtype")]
	[Compact]
	public class Path {
		public void arc (float center_x, float center_y, float radius_x, float radius_y, float angle_1, float angle_2);
		public void close ();
		public Cogl.Path copy ();
		public void curve_to (float x_1, float y_1, float x_2, float y_2, float x_3, float y_3);
		public void ellipse (float center_x, float center_y, float radius_x, float radius_y);
		public void fill ();
		public void fill_preserve ();
		public Cogl.PathFillRule get_fill_rule ();
		public void line (float x_1, float y_1, float x_2, float y_2);
		public void line_to (float x, float y);
		public void move_to (float x, float y);
		public Path ();
		public void polygon ([CCode (array_length = false)] float[] coords, int num_points);
		public void polyline ([CCode (array_length = false)] float[] coords, int num_points);
		public void rectangle (float x_1, float y_1, float x_2, float y_2);
		public void rel_curve_to (float x_1, float y_1, float x_2, float y_2, float x_3, float y_3);
		public void rel_line_to (float x, float y);
		public void rel_move_to (float x, float y);
		public void round_rectangle (float x_1, float y_1, float x_2, float y_2, float radius, float arc_step);
		public void set_fill_rule (Cogl.PathFillRule fill_rule);
		public void stroke ();
		public void stroke_preserve ();
	}
	[CCode (cheader_filename = "cogl-path/cogl-path.h", cprefix = "COGL_PATH_FILL_RULE_", has_type_id = false)]
	public enum PathFillRule {
		NON_ZERO,
		EVEN_ODD
	}
}
