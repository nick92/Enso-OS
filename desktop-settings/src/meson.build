plug_files = files(
    'Cache.vala',
    'Desktop.vala',
    'DesktopWindow.vala',
    'GalaSettings.vala',
    'Widgets/WallpaperContainer.vala',
    'Widgets/SolidColorContainer.vala',
    'Views/Wallpaper.vala',
    'Views/HotCorners.vala',
    'Views/Dock.vala',
    'Views/Launchy.vala'
)

plank_datadir = plank_dep.get_pkgconfig_variable('pkgdatadir')

configuration = configuration_data()
configuration.set('PLANKDATADIR', plank_datadir)

config_file = configure_file(
    input: 'Config.vala.in',
    output: '@BASENAME@',
    configuration: configuration
)

executable(
    meson.project_name(),
    plug_files,
    config_file,
    plug_resources,
    dependencies: [
        glib_dep,
        gio_dep,
        gobject_dep,
        granite_dep,
        gtk_dep,
        dependency('gnome-desktop-3.0'),
        plank_dep,
        posix_dep
    ],
    install: true
)