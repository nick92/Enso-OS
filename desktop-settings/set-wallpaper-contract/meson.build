contract_exec_name = 'io.elementary.contract.set-wallpaper'
contract_path = libexecdir

contract_configuration = configuration_data()
contract_configuration.set('EXEC_NAME', contract_exec_name)
contract_configuration.set('SWEXECDIR', join_paths(get_option('prefix'), contract_path))
contract_configuration.set('GETTEXT_DOMAIN', gettext_name)

wallpaper_contract = configure_file(
    input: 'set-wallpaper.contract.in',
    output: '@BASENAME@',
    configuration: contract_configuration,
    install_dir: join_paths(datadir, 'contractor')
)

executable(
    contract_exec_name,
    'set-wallpaper.vala',
    dependencies: [
        glib_dep,
        gio_dep,
        gobject_dep,
        gtk_dep,
        posix_dep,
        meson.get_compiler('c').find_library('m')
    ],
    install: true,
    install_dir: contract_path
)
