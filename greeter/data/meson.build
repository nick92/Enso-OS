conf_data = configuration_data()
conf_data.set('GETTEXT_PACKAGE', meson.project_name())
conf_data.set('PROJECT_NAME', meson.project_name())

desktop_in = configure_file (
    input: meson.project_name() + '.desktop.in.in',
    output: meson.project_name() + '.desktop.in',
    configuration: conf_data
)

i18n.merge_file (
    'desktop',
    input: desktop_in,
    output: meson.project_name() + '.desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'xgreeters'),
    po_dir: join_paths(meson.source_root (), 'po'),
    type: 'desktop'
)

# i18n.merge_file(
#     input: 'greeter.appdata.xml.in',
#     output: meson.project_name() + '.appdata.xml',
#     po_dir: join_paths(meson.source_root(), 'po', 'extra'),
#     type: 'xml',
#     install: true,
#     install_dir: join_paths(get_option('datadir'), 'metainfo'),
# )

install_data(
    meson.project_name() + '.conf',
    install_dir: join_paths(get_option('sysconfdir'), 'lightdm')
)

test (
    'Validate desktop file',
    find_program('desktop-file-validate'),
    args: join_paths(meson.current_build_dir (), meson.project_name() + '.desktop')
)
