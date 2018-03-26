gala_pip_sources = [
	'Main.vala',
	'MoveAction.vala',
	'PopupWindow.vala',
	'SelectionArea.vala',
	'ShadowEffect.vala',
]

gala_pip_lib = shared_library(
	'gala-pip',
	gala_pip_sources,
	dependencies: [gala_dep, gala_base_dep],
	include_directories: config_inc_dir,
	install: true,
	install_dir: plugins_dir,
	install_rpath: mutter_typelib_dir,
)
