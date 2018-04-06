plank_appdata = i18n.merge_file(
	input: 'plank.appdata.xml.in',
	output: 'plank.appdata.xml',
	po_dir: '../po',
	type: 'xml',
	install: true,
	install_dir: join_paths(data_dir, 'appdata')
)

plank_gschema = configure_file(
	input: 'net.launchpad.plank.gschema.xml.in',
	output: 'net.launchpad.plank.gschema.xml',
	configuration: customconf,
	install: true,
	install_dir: join_paths(data_dir, 'glib-2.0', 'schemas')
)

plank_gschema_compile = gnome.compile_schemas(
	depend_files: plank_gschema,
)

i18n.merge_file(
	input: 'plank.desktop.in',
	output: 'plank.desktop',
	po_dir: '../po',
	type: 'desktop',
	install: true,
	install_dir: join_paths(data_dir, 'applications')
)

icons_dir = join_paths(get_option('datadir'), 'icons', 'hicolor')
install_data('icons/16x16/plank.svg', install_dir: join_paths(icons_dir, '16x16', 'apps'))
install_data('icons/22x22/plank.svg', install_dir: join_paths(icons_dir, '22x22', 'apps'))
install_data('icons/24x24/plank.svg', install_dir: join_paths(icons_dir, '24x24', 'apps'))
install_data('icons/32x32/plank.svg', install_dir: join_paths(icons_dir, '32x32', 'apps'))
install_data('icons/48x48/plank.svg', install_dir: join_paths(icons_dir, '48x48', 'apps'))
install_data('icons/64x64/plank.svg', install_dir: join_paths(icons_dir, '64x64', 'apps'))
install_data('icons/128x128/plank.svg', install_dir: join_paths(icons_dir, '128x128', 'apps'))

themes_dir = join_paths(pkgdata_dir, 'themes')
install_subdir('themes/Default', install_dir: themes_dir)
install_subdir('themes/Matte', install_dir: themes_dir)
install_subdir('themes/Transparent', install_dir: themes_dir)

# Installation of Apport support files
enable_apport = get_option('enable-apport')
if enable_apport
	install_data('apport/source_plank.py', install_dir: join_paths(get_option('datadir'), 'apport', 'package-hooks'))
	install_data('apport/plank-crashdb.conf', install_dir: join_paths(get_option('sysconfdir'), 'apport', 'crashdb.conf.d'))
endif
