plug_files = files(
    'Keyboard.vala',
    'KeyboardWindow.vala',
    'Widgets/Shortcuts/SectionSwitcher.vala',
    'Widgets/Shortcuts/Tree.vala',
    'Widgets/Shortcuts/Display.vala',
    'Widgets/Shortcuts/DisplayTree.vala',
    'Widgets/Shortcuts/CustomTree.vala',
    'Widgets/Layout/Display.vala',
    'Widgets/Layout/AddLayoutPopover.vala',
    'Views/Shortcuts.vala',
    'Views/Layout.vala',
    'Views/Behavior.vala',
    'Views/AbstractPage.vala',
    'Shortcuts/Shortcut.vala',
    'Shortcuts/Settings.vala',
    'Shortcuts/XfceSettings.vala',
    'Shortcuts/List.vala',
    'Shortcuts/CustomShortcutSettings.vala',
    'Layout/XkbModifier.vala',
    'Layout/Settings.vala',
    'Layout/Handler.vala',
    'Layout/AdvancedSettingsPanel.vala',
    'Layout/AdvancedSettingsGrid.vala',
    'Dialogs/ConflictDialog.vala',
    'Behavior/Settings.vala'
)

glib = dependency('glib-2.0')
gio_dep =        dependency('gio-2.0')
goobject_dep =        dependency('gobject-2.0')
granite_dep =        dependency('granite')
gtk_dep =        dependency('gtk+-3.0')
libxml =        dependency('libxml-2.0')
libxconf = dependency('libxfconf-0')
# libgnomekbd =        dependency('libgnomekbd')

dependencies = [
    glib,
    gio_dep,
    goobject_dep,
    granite_dep,
    gtk_dep,
    libxml,
    libxconf
]

config_file = configure_file(
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: conf_data
)

executable(
    meson.project_name(),
    plug_files,
    config_file,
    dependencies: dependencies,
    install: true
)