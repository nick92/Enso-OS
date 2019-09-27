# Appdata file
# i18n.merge_file(
#     input: 'io.elementary.switchboard.mouse-touchpad.appdata.xml.in',
#     output: 'io.elementary.switchboard.mouse-touchpad.appdata.xml',
#     po_dir: join_paths(meson.source_root (), 'po', 'extra'),
#     install_dir: join_paths(datadir, 'metainfo'),
#     install: true
# )

# Desktop File
# desktop_in = configure_file(
#     input: meson.project_name() + '.desktop.in',
#     output: '@BASENAME@',
#     configuration: conf_data
# )

i18n.merge_file(
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    po_dir: join_paths(meson.source_root (), 'po', 'extra'),
    type: 'desktop',
    install_dir: join_paths(get_option('datadir'), 'applications'),
    install: true
)