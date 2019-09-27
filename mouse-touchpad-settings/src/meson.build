plug_files = files(
    'Mouse.vala',
    'MouseWindow.vala',
    'Backend/MouseSettings.vala',
    'Backend/TouchpadSettings.vala',
    'Views/General.vala',
    'Views/Mouse.vala',
    'Views/Touchpad.vala',
    'Widgets/SettingLabel.vala',
)

config_file = configure_file(
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: conf_data
)

executable(
    meson.project_name(),
    icon_res,
    plug_files,
    config_file,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gio-2.0'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0')
    ],
    install: true
)
