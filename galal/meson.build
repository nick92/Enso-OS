project('gala',
	'c', 'vala',
	version: '0.3.1',
	meson_version: '>= 0.42.0',
	license: 'GPL3',
)

is_release = false

gnome = import('gnome')
i18n = import('i18n')
cc = meson.get_compiler('c')

gala_version = meson.project_version()

vala_version_required = '0.28.0'
vala = meson.get_compiler('vala')
if not vala.version().version_compare('>= @0@'.format(vala_version_required))
	error('Valac >= @0@ required!'.format(vala_version_required))
endif


data_dir = join_paths(get_option('prefix'), get_option('datadir'))
plugins_dir = join_paths(get_option('prefix'), get_option('libdir'), meson.project_name(), 'plugins')
pkgdata_dir = join_paths(get_option('prefix'), get_option('datadir'), meson.project_name())
pkglib_dir = join_paths(get_option('prefix'), get_option('libdir'), meson.project_name())

config_inc_dir = include_directories('.')

conf = configuration_data()
conf.set_quoted('PACKAGE', meson.project_name())
conf.set_quoted('PACKAGE_BUGREPORT', 'https://github.com/elementary/gala/issues')
conf.set_quoted('PACKAGE_NAME', meson.project_name())
conf.set_quoted('PACKAGE_STRING', 'Gala')
conf.set_quoted('PACKAGE_TARNAME', meson.project_name())
conf.set_quoted('PACKAGE_URL', 'https://github.com/elementary/gala')
conf.set_quoted('PACKAGE_VERSION', gala_version)
conf.set_quoted('DATADIR', data_dir)
conf.set_quoted('PKGDATADIR', pkgdata_dir)
conf.set_quoted('PKGLIBDIR', pkglib_dir)
conf.set_quoted('PLUGINSDIR', plugins_dir)
conf.set_quoted('RELEASE_NAME', 'Window Manager.')
conf.set_quoted('VERSION', gala_version)
conf.set_quoted('VERSION_INFO', (is_release ? 'Release' : 'Development'))
conf.set_quoted('BUILD_VERSION', gala_version)
configure_file(input: 'config.h.meson', output: 'config.h', configuration: conf)

customconf = configuration_data()
customconf.set('GETTEXT_PACKAGE', meson.project_name())

pkgconf = configuration_data()
pkgconf.set('PACKAGE_VERSION', gala_version)
pkgconf.set('MUTTER_CFLAGS', '')
pkgconf.set('prefix', get_option('prefix'))
pkgconf.set('exec_prefix', '${prefix}')
pkgconf.set('libdir', '${prefix}/@0@'.format(get_option('libdir')))
pkgconf.set('bindir', '${exec_prefix}/@0@'.format(get_option('bindir')))
pkgconf.set('datarootdir', '${prefix}/@0@'.format(get_option('datadir')))
pkgconf.set('datadir', '${datarootdir}')
pkgconf.set('includedir', '${prefix}/@0@'.format(get_option('includedir')))


add_project_arguments([
		'--target-glib=2.44',
		'--hide-internal',
		'--enable-deprecated',
		'--vapidir=' + join_paths(meson.source_root(), 'vapi'),
		'--pkg', 'config',
		'--pkg', 'cogl-fixes',
		'--pkg', 'compat',
	],
	language: 'vala',
)
add_project_arguments([
		'-Wno-discarded-qualifiers',
		'-Wno-incompatible-pointer-types',
		'-Wno-unused',
		'-Wl,--enable-new-dtags',

		'-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
		'-DGNOME_DESKTOP_USE_UNSTABLE_API',

		'-DDATADIR="@0@"'.format(data_dir),
		'-DPKGDATADIR="@0@"'.format(pkgdata_dir),
		'-DPKGLIBDIR="@0@"'.format(pkglib_dir),
		'-DPLUGINDIR="@0@"'.format(plugins_dir),
		'-DSCHEMA="org.pantheon.desktop.gala"',
		'-DRESOURCEPATH="/org/pantheon/desktop/gala"',

		'-DGLIB_VERSION_MIN_REQUIRED=GLIB_VERSION_2_44',
		'-DGLIB_VERSION_MAX_ALLOWED=GLIB_VERSION_2_44',
		'-DGDK_VERSION_MIN_REQUIRED=GDK_VERSION_3_10',
		'-DGDK_VERSION_MAX_ALLOWED=GDK_VERSION_3_10',
	],
	language: 'c',
)


# Dependencies
glib_version_required = '2.44.0'
gtk_version_required = '3.10.0'
plank_version_required = '0.11.0'
gsd_version_required = '3.15.2'

glib_dep = [dependency('gio-2.0', version: '>= @0@'.format(glib_version_required)), dependency('gio-unix-2.0'), dependency('gmodule-2.0')]
gtk_dep = [dependency('gtk+-3.0', version: '>= @0@'.format(gtk_version_required)), dependency('gdk-x11-3.0')]
gee_dep = dependency('gee-0.8')
bamf_dep = dependency('libbamf3')
plank_dep = dependency('plank', version: '>= @0@'.format(plank_version_required))
granite_dep = dependency('granite')
gnome_desktop_dep = dependency('gnome-desktop-3.0')
gsd_dep = dependency('gnome-settings-daemon', version: '>= @0@'.format(gsd_version_required))
m_dep = cc.find_library('m', required: false)
xfconf_dep = dependency('libxfconf-0')

mutter_dep = []
libmutter_dep = []

vala_flags = []

mutter318_dep = dependency('libmutter', version: ['>= 3.18.3', '< 3.19'], required: false)
if mutter318_dep.found()
	mutter_packages_command = [
		'--pkg', 'libmutter',
		'--pkg', 'cogl-1.0',
		'--pkg', 'clutter-1.0'
	]
	libmutter_dep = dependency('libmutter')
	pkgconf.set('MUTTER_PKGS', 'libmutter >= 3.18.3')
	mutter_dep = [libmutter_dep, dependency('cogl-1.0'), dependency('clutter-1.0')]
endif

mutter320_dep = dependency('libmutter', version: ['>= 3.19', '< 3.21'], required: false)
if mutter320_dep.found()
	mutter_packages_command = [
		'--pkg', 'libmutter',
		'--pkg', 'cogl-1.0',
		'--pkg', 'clutter-1.0'
	]
	libmutter_dep = dependency('libmutter', version: '>= 3.20.3')
	pkgconf.set('MUTTER_PKGS', 'libmutter >= 3.20.3')
	mutter_dep = [libmutter_dep, dependency('cogl-1.0'), dependency('clutter-1.0')]
	vala_flags += ['--define', 'HAS_MUTTER320']
endif

mutter322_dep = dependency('libmutter', version: ['>= 3.21', '< 3.23'], required: false)
if mutter322_dep.found()
	mutter_packages_command = [
		'--pkg', 'libmutter',
		'--pkg', 'mutter-cogl-1.0',
		'--pkg', 'mutter-cogl-pango-1.0',
		'--pkg', 'mutter-cogl-path-1.0',
		'--pkg', 'mutter-clutter-1.0'
	]
	libmutter_dep = dependency('libmutter', version: '>= 3.22.0')
	pkgconf.set('MUTTER_PKGS', 'libmutter >= 3.22.0')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-cogl-1.0'), dependency('mutter-cogl-pango-1.0'),
		dependency('mutter-cogl-path-1.0'), dependency('mutter-clutter-1.0')
	]
	vala_flags += ['--define', 'HAS_MUTTER320', '--define', 'HAS_MUTTER322']
	add_project_arguments(['-DCLUTTER_ENABLE_COMPOSITOR_API', '-DCLUTTER_ENABLE_EXPERIMENTAL_API',
		'-DCOGL_ENABLE_EXPERIMENTAL_API', '-DCOGL_ENABLE_EXPERIMENTAL_2_0_API'], language: 'c')
endif

mutter324_dep = dependency('libmutter-0', version: ['>= 3.23', '< 3.25'], required: false)
if mutter324_dep.found()
	mutter_packages_command = [
		'--pkg', 'libmutter-0',
		'--pkg', 'mutter-cogl-0',
		'--pkg', 'mutter-cogl-pango-0',
		'--pkg', 'mutter-cogl-path-0',
		'--pkg', 'mutter-clutter-0'
	]
	libmutter_dep = dependency('libmutter-0', version: '>= 3.24.0')
	pkgconf.set('MUTTER_PKGS', 'libmutter-0 >= 3.24.0')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-cogl-0'), dependency('mutter-cogl-pango-0'),
		dependency('mutter-cogl-path-0'), dependency('mutter-clutter-0')
	]
	vala_flags += ['--define', 'HAS_MUTTER320', '--define', 'HAS_MUTTER322', '--define', 'HAS_MUTTER324']
	add_project_arguments(['-DCLUTTER_ENABLE_COMPOSITOR_API', '-DCLUTTER_ENABLE_EXPERIMENTAL_API',
		'-DCOGL_ENABLE_EXPERIMENTAL_API', '-DCOGL_ENABLE_EXPERIMENTAL_2_0_API'], language: 'c')
endif

mutter326_dep = dependency('libmutter-1', version: ['>= 3.25', '< 3.27'], required: false)
if mutter326_dep.found()
	mutter_packages_command = [
		'--pkg', 'libmutter-1',
		'--pkg', 'mutter-cogl-1',
		'--pkg', 'mutter-cogl-pango-1',
		'--pkg', 'mutter-cogl-path-1',
		'--pkg', 'mutter-clutter-1'
	]
	libmutter_dep = dependency('libmutter-1', version: '>= 3.26.0')
	pkgconf.set('MUTTER_PKGS', 'libmutter-1 >= 3.26.0')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-cogl-1'), dependency('mutter-cogl-pango-1'),
		dependency('mutter-cogl-path-1'), dependency('mutter-clutter-1')
	]
	vala_flags += ['--define', 'HAS_MUTTER320', '--define', 'HAS_MUTTER322', '--define', 'HAS_MUTTER324', '--define', 'HAS_MUTTER326']
	add_project_arguments(['-DCLUTTER_ENABLE_COMPOSITOR_API', '-DCLUTTER_ENABLE_EXPERIMENTAL_API',
		'-DCOGL_ENABLE_EXPERIMENTAL_API', '-DCOGL_ENABLE_EXPERIMENTAL_2_0_API'], language: 'c')
endif

mutter328_dep = dependency('libmutter-2', version: ['>= 3.27', '< 3.29'], required: false)
if mutter328_dep.found()
	mutter_packages_command = [
		'--pkg', 'libmutter-2',
		'--pkg', 'mutter-cogl-2',
		'--pkg', 'mutter-cogl-pango-2',
		'--pkg', 'mutter-cogl-path-2',
		'--pkg', 'mutter-clutter-2'
	]
	libmutter_dep = dependency('libmutter-2', version: '>= 3.27.92')
	pkgconf.set('MUTTER_PKGS', 'libmutter-2 >= 3.27.92')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-cogl-2'), dependency('mutter-cogl-pango-2'),
		dependency('mutter-cogl-path-2'), dependency('mutter-clutter-2')
	]
	vala_flags += ['--define', 'HAS_MUTTER320', '--define', 'HAS_MUTTER322', '--define', 'HAS_MUTTER324', '--define', 'HAS_MUTTER326', '--define', 'HAS_MUTTER328']
	add_project_arguments(['-DCLUTTER_ENABLE_COMPOSITOR_API', '-DCLUTTER_ENABLE_EXPERIMENTAL_API',
		'-DCOGL_ENABLE_EXPERIMENTAL_API', '-DCOGL_ENABLE_EXPERIMENTAL_2_0_API'], language: 'c')
endif

if mutter_dep.length() == 0
	error ('No supported mutter library found!')
endif

mutter_typelib_dir = libmutter_dep.get_pkgconfig_variable('typelibdir')

add_project_arguments(vala_flags, language: 'vala')
add_project_link_arguments(['-Wl,-rpath,@0@'.format(mutter_typelib_dir)], language: 'c')

gala_base_dep = [glib_dep, gee_dep, gtk_dep, plank_dep, bamf_dep, mutter_dep, granite_dep, gnome_desktop_dep, m_dep]

subdir('data')
subdir('lib')
subdir('src')
#subdir('plugins/maskcorners')
subdir('plugins/notify')
#subdir('plugins/pip')
#subdir('plugins/template')
subdir('plugins/zoom')
if get_option('documentation')
	subdir('docs')
endif
subdir('po')

meson.add_install_script('meson/post_install.py')
