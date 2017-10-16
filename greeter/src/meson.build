sources = [
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
    'Widgets/FingerprintCredentials.vala',
    'Widgets/LoginBox.vala',
    'Widgets/LoginButtonCredentials.vala',
    'Widgets/PasswordCredentials.vala',
    'Widgets/TimeLabel.vala',
    'Widgets/PowerLabel.vala',
    'Widgets/Wallpaper.vala',
    greeter_resources
]

executable ('greeter',
            sources,
            dependencies: [glib, gtk, lightdm, gtkx11, clutter, cluttergtk, gtkpixbuf, gee, gl],
            vala_args:['--target-glib=2.38', '--gresources=' + meson.source_root () + '/data/gresource.xml'],
            install: true
            )
