project(
    'datetime',
    'vala', 'c',
    version: '2.2.5'
)

i18n = import('i18n')
gnome = import('gnome')

gettext_name = meson.project_name() + '-plugin'

prefix = get_option('prefix')
libdir = join_paths(prefix, get_option('libdir'))

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_name), language:'c')
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')

gresource = gnome.compile_resources(
    'gresource',
    join_paths('data', 'css.gresource.xml'),
    source_dir: 'data'
)

lib_panel_plugins_sdir = join_paths(get_option('libdir'), 'xfce4' , 'panel', 'plugins')

libecal_dep = dependency('libecal-2.0', required: false)
if libecal_dep.found()
    libical_dep = dependency('libical-glib')
    add_project_arguments('--define=E_CAL_2_0', language: 'vala')
    add_project_arguments('-DLIBICAL_GLIB_UNSTABLE_API=1', language: 'c')
else
    libecal_dep = dependency('libecal-1.2', version: '>=3.8.0')
    libical_dep = dependency('libical')
    add_project_arguments('--vapidir', join_paths(meson.current_source_dir(), 'vapi'), language: 'vala')
endif

shared_module(
    meson.project_name(),
    gresource,
    'src/XfcePanelPlug.vala',
    'src/Indicator.vala',
    'src/DateIterator.vala',
    'src/DateRange.vala',
    'src/Widgets/PanelLabel.vala',
    # 'src/Widgets/calendar/Calendar.vala',
    'src/Widgets/EventRow.vala',
    'src/Widgets/calendar/CalendarModel.vala',
    'src/Widgets/calendar/CalendarView.vala',
    # 'src/Widgets/calendar/ControlHeader.vala',
    'src/Widgets/calendar/Util.vala',
    'src/Widgets/calendar/Grid.vala',
    'src/Widgets/calendar/GridDay.vala',
    'src/Widgets/calendar/Header.vala',
    'src/Widgets/calendar/WeekLabels.vala',
    'src/Services/TimeManager.vala',
    'src/Services/ClockSettings.vala',
    'src/Services/SettingsManager.vala',
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        libecal_dep,
        dependency('libedataserver-1.2'),
        dependency('libxfce4panel-2.0'),
        dependency('libxfconf-0'),
        libical_dep,
    ],
    install: true,
    install_dir : lib_panel_plugins_sdir,
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')