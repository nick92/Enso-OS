project(
    'desktop-settings',
    'vala', 'c',
    version: '2.8.4'
)
gettext_name = meson.project_name()
gnome = import('gnome')
i18n = import('i18n')

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
libdir = join_paths(prefix, get_option('libdir'))
libexecdir = join_paths(prefix, get_option('libexecdir'))

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    '-DGNOME_DESKTOP_USE_UNSTABLE_API',
    language: 'c'
)

add_project_arguments(
    ['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
    language: 'vala'
)

gio_dep = dependency('gio-2.0')
glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
granite_dep = dependency('granite', version: '>=0.2')
gtk_dep = dependency('gtk+-3.0', version: '>= 3.22')
plank_dep = dependency('plank', version: '>=0.10.9')
posix_dep = meson.get_compiler('vala').find_library('posix')

plug_resources = gnome.compile_resources(
    'plug_resources',
    'data/css.gresource.xml',
    source_dir: 'data'
)

subdir('data')
subdir('src')
subdir('set-wallpaper-contract')
subdir('po')