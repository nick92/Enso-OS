project(
    'keyboard-settings',
    'vala', 'c',
    version: '2.3.5'
)

gettext_name = meson.project_name()
gnome = import('gnome')
i18n = import('i18n')

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
libdir = join_paths(prefix, get_option('libdir'))

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    language:'c'
)


add_project_arguments(
    ['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
    language: 'vala'
)

conf_data = configuration_data()
conf_data.set('GETTEXT_PACKAGE', meson.project_name())
conf_data.set('VERSION', meson.project_version())


# subdir('data')
subdir('src')
# subdir('po')