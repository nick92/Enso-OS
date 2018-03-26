valadoc = find_program('valadoc')

basic_command = [
    valadoc,
    '--force',
    '--verbose',
    '--package-name','gala',
    '--package-version', '0.0.0',
    '--driver', meson.get_compiler('vala').version(),
    mutter_packages_command,
    '--pkg', 'libbamf3',
    '--pkg', 'plank',
    '--pkg', 'gnome-desktop-3.0',
    '--pkg', 'gtk+-3.0',
    '--pkg', 'gee-0.8',
    '--pkg', 'gio-unix-2.0',
    '--pkg', 'gmodule-2.0',
    '--pkg', 'config',
    '--pkg', 'compat',
    '--pkg', 'cogl-fixes',
    vala_flags,
    '--vapidir=' + join_paths(meson.build_root(), 'lib'),
    '--vapidir=' + join_paths(meson.source_root(), 'vapi'),
    '--doclet=html',
    '--use-svg-images'
]

doc_target = custom_target(
    'library documentation',
    command: [
        basic_command,
        '-o', '@OUTPUT@',
        '@INPUT@'
    ],
    build_by_default: true,
    input: gala_lib_sources,
    output: 'library'
)

all_doc_target = custom_target(
    'full documentation',
    command: [
        basic_command,
        '--internal',
        '--pkg', 'granite',
        '--pkg', 'gnome-desktop-3.0',
        '--pkg', 'gmodule-2.0',
        '-o', '@OUTPUT@',
        '@INPUT@'
    ],
    build_by_default: true,
    input: gala_lib_sources + gala_bin_sources,
    output: 'full'
)
