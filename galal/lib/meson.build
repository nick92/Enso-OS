gala_lib_sources = files(
	'ActivatableComponent.vala',
	'Plugin.vala',
	'Utils.vala',
	'WindowIcon.vala',
	'WindowManager.vala',
)

gala_resources = gnome.compile_resources(
	'gala-resources',
	join_paths(meson.source_root(), 'data', 'gala.gresource.xml'),
	source_dir: join_paths(meson.source_root(), 'data'),
	c_name: 'gala',
)

gala_lib = shared_library(
	'gala',
	gala_lib_sources,
	gala_resources,
	dependencies: [gala_base_dep],
	include_directories: config_inc_dir,
	install: true,
	install_dir: [true, join_paths(get_option('includedir'), 'gala'), true],
	install_rpath: mutter_typelib_dir,
	version : '0.0.0',
	vala_args: [
		'--pkg', 'config',
		'--pkg', 'compat',
	],
)

install_data('gala.deps', install_dir: join_paths(get_option('datadir'), 'vala', 'vapi'))

gala_dep = declare_dependency(link_with: [gala_lib], include_directories: include_directories('.'))

configure_file(
	input: 'gala.pc.in',
	output: 'gala.pc',
	configuration: pkgconf,
	install_dir: join_paths(get_option('libdir'), 'pkgconfig'),
)
