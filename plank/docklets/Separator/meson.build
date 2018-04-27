docklet_separator_sources = [
	'SeparatorDockItem.vala',
	'SeparatorDocklet.vala',
]

docklet_separator_resources = gnome.compile_resources(
	'docky-separator-resources',
	'separator.gresource.xml',
	c_name: 'docky_separator',
)

docklet_separator = shared_module(
	'docklet-separator',
	docklet_separator_sources,
	docklet_separator_resources,
	dependencies: [plank_dep, plank_base_dep, wnck_x11_dep],
	install: true,
	install_dir: docklets_dir,
)
