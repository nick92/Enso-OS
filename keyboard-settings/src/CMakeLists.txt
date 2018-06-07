find_package (PkgConfig)

# Add all your dependencies to the list below
pkg_check_modules (DEPS REQUIRED gthread-2.0 gtk+-3.0>=3.10 granite libxml-2.0 gee-0.8 glib-2.0>=2.39 gdk-x11-3.0 libxfconf-0)

add_definitions (${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.22.0" MINIMUM)

include (ValaPrecompile)
# Add all your vala files and required packages to the List below to include them in the build
vala_precompile (VALA_C ${CMAKE_PROJECT_NAME}
    Keyboard.vala
    KeyboardWindow.vala

    Behavior/Settings.vala

    Dialogs/ConflictDialog.vala

    Layout/AdvancedSettingsPanel.vala
    Layout/AdvancedSettingsGrid.vala
    Layout/Handler.vala
    Layout/Settings.vala
    Layout/XkbModifier.vala

    Shortcuts/CustomShortcutSettings.vala
    Shortcuts/List.vala
    Shortcuts/Settings.vala
    Shortcuts/XfceSettings.vala
    Shortcuts/Shortcut.vala

    Views/AbstractPage.vala
    Views/Behavior.vala
    Views/Layout.vala
    Views/Shortcuts.vala

    Widgets/Layout/AddLayoutPopover.vala
    Widgets/Layout/Display.vala

    Widgets/Shortcuts/CustomTree.vala
    Widgets/Shortcuts/Display.vala
    Widgets/Shortcuts/DisplayTree.vala
    Widgets/Shortcuts/SectionSwitcher.vala
    Widgets/Shortcuts/Tree.vala

    ${CMAKE_CURRENT_BINARY_DIR}/config.vala
PACKAGES
    gtk+-3.0
    granite
    gee-0.8
    libxml-2.0
    glib-2.0
    gdk-x11-3.0
CUSTOM_VAPIS
    ${CMAKE_SOURCE_DIR}/vapi/libxfconf-0.vapi
OPTIONS
    --thread
)

add_definitions(${CFLAGS} -Wall -Winit-self -Wwrite-strings -Wunreachable-code -Wstrict-prototypes)
add_executable(${CMAKE_PROJECT_NAME} ${VALA_C})

install (TARGETS ${CMAKE_PROJECT_NAME} RUNTIME DESTINATION bin)
