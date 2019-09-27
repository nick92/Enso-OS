# actservice_dep = dependency('accountsservice')
gobject_dep = dependency('gobject-2.0')
glib_dep = dependency('glib-2.0')
gtk_dep = dependency('gtk+-3.0')
granite_dep = dependency('granite')
lightdm_dep = dependency('liblightdm-gobject-1')
clutter_gtk_dep = dependency('clutter-gtk-1.0')
gdk_pixbuf_dep = dependency('gdk-pixbuf-2.0')
gdk_x11_dep = dependency('gdk-x11-3.0')
gl_dep = dependency('gl')

install_path = join_paths(get_option('prefix'), get_option('sbindir'))

conf_data = configuration_data()
conf_data.set('CONF_DIR', join_paths(get_option('sysconfdir'), 'lightdm'))
conf_data.set('GETTEXT_PACKAGE', meson.project_name())

gsd_dir = join_paths(get_option('prefix'), 'lib', 'gnome-settings-daemon' + '/')

conf_data.set('GSD_DIR', gsd_dir)
conf_data.set('VERSION', meson.project_version())
config_header = configure_file (
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: conf_data
)

cogl_fixes = join_paths(meson.source_root(), 'vapi', 'cogl-fixes.vapi')

executable(
    meson.project_name(),
    'PantheonGreeter.vala',
    'SettingsDaemon.vala',
    'UserList.vala',
    'UserListActor.vala',

    'Gateways/DummyGateway.vala',
    'Gateways/LightDMGateway.vala',
    'Gateways/LoginGateway.vala',

    'Interfaces/Credentials.vala',
    'Interfaces/LoginMask.vala',

    'LoginOptions/GuestLogin.vala',
    'LoginOptions/LoginOption.vala',
    'LoginOptions/ManualLogin.vala',
    'LoginOptions/UserLogin.vala',

    'Widgets/CredentialsArea.vala',
    'Widgets/DeepinBlurEffect.vala',
    'Widgets/FingerprintCredentials.vala',
    'Widgets/LoginBox.vala',
    'Widgets/LoginButtonCredentials.vala',
    'Widgets/PasswordCredentials.vala',
    'Widgets/TimeLabel.vala',
    'Widgets/PowerLabel.vala',
    'Widgets/Wallpaper.vala',
    'Widgets/Avatar.vala',

    greeter_resources,
    cogl_fixes,
    config_header,
    dependencies: [ gobject_dep, glib_dep, gtk_dep, granite_dep, lightdm_dep, clutter_gtk_dep, gdk_x11_dep, gdk_pixbuf_dep, gl_dep ],
    install : true,
    install_dir: install_path
)
