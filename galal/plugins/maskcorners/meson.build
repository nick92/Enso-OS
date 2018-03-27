gala_maskcorners_sources = [
	'Main.vala',
	'Settings.vala',
]

gala_maskcorners_lib = shared_library(
	'gala-maskcorners',
	gala_maskcorners_sources,
	dependencies: [gala_dep, gala_base_dep],
	include_directories: config_inc_dir,
	install: true,
	install_dir: plugins_dir,
	install_rpath: mutter_typelib_dir,
)
