gala_zoom_sources = [
	'Main.vala',
]

gala_zoom_lib = shared_library(
	'gala-zoom',
	gala_zoom_sources,
	dependencies: [gala_dep, gala_base_dep],
	include_directories: config_inc_dir,
	install: true,
	install_dir: plugins_dir,
	install_rpath: mutter_typelib_dir,
)
