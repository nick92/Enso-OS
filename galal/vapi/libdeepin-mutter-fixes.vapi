[CCode (cprefix = "Meta", gir_namespace = "Meta", gir_version = "3.0", lower_case_cprefix = "meta_")]
namespace Meta {
    [CCode (cname = "meta_verbose_real", cheader_filename = "meta/main.h")]
    public static void verbose (string format, ...);

    [CCode (cheader_filename = "meta/main.h", cname = "meta_topic_real")]
    public static void topic (Meta.DebugTopic topic, string format, ...);

#if HAS_MUTTER314
    [CCode (cheader_filename = "meta/main.h", cname = "meta_set_debugging")]
    public static void set_debugging (bool setting);
    [CCode (cheader_filename = "meta/main.h", cname = "meta_set_verbose")]
    public static void set_verbose (bool setting);
#endif

    [CCode (cheader_filename = "meta/meta-blur-effect.h", type_id = "meta_blur_effect_get_type ()")]
    public class BlurEffect : Clutter.OffscreenEffect {
        [CCode (has_construct_function = false, type = "ClutterEffect*")]
            public BlurEffect (int radius);
    }

	[CCode (cheader_filename = "meta/meta-blurred-background-actor.h", type_id = "meta_blurred_background_actor_get_type ()")]
	public class BlurredBackgroundActor : Clutter.Actor, Atk.Implementor, Clutter.Animatable, Clutter.Container, Clutter.Scriptable {
		[CCode (has_construct_function = false, type = "ClutterActor*")]
		public BlurredBackgroundActor (Meta.Screen screen, int monitor);
		public void set_background (Meta.Background background);
		public void set_radius (int radius);
		public void set_rounds (int rounds);
        public void set_blur_mask (Cairo.Surface? mask);
		[NoAccessorMethod]
		public Meta.Background background { owned get; set; }
		[NoAccessorMethod]
		public int radius { get; set; }
		[NoAccessorMethod]
		public Meta.Screen meta_screen { owned get; construct; }
		[NoAccessorMethod]
		public int monitor { get; construct; }
	}

	[CCode (cheader_filename = "meta/meta-blur-actor.h", type_id = "meta_blur_actor_get_type ()")]
	public class BlurActor : Clutter.Actor, Atk.Implementor, Clutter.Animatable, Clutter.Container, Clutter.Scriptable {
		[CCode (has_construct_function = false, type = "ClutterActor*")]
		public BlurActor (Meta.Screen screen);
		public void set_radius (int radius);
		public void set_rounds (int rounds);
        public void set_blur_mask (Cairo.Surface? mask);
		[NoAccessorMethod]
		public int radius { get; set; }
		[NoAccessorMethod]
		public Meta.Screen meta_screen { owned get; construct; }
	}
}
