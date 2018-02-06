find_package (PkgConfig)

# Add all your dependencies to the list below
pkg_check_modules (DEPS REQUIRED gthread-2.0 gtk+-3.0 granite gee-0.8 gnome-desktop-3.0 accountsservice polkit-gobject-1 pwquality)

add_definitions (${DEPS_CFLAGS} -DGNOME_DESKTOP_USE_UNSTABLE_API)
link_libraries (${DEPS_LIBRARIES})
link_directories (${DEPS_LIBRARY_DIRS})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.34.1" MINIMUM)

include (ValaPrecompile)
# Add all your vala files and requires packages to the List below to include them in the build
vala_precompile (VALA_C ${CMAKE_PROJECT_NAME}
    Plug.vala
	UserAccountWindow.vala
    Dialogs/AvatarDialog.vala
    Misc/Utils.vala
    Misc/UserUtils.vala
    Misc/InfobarNotifier.vala
    Views/GuestSettingsView.vala
    Views/MainView.vala
    Views/UserSettingsView.vala
    Widgets/UserListBox.vala
    Widgets/ListFooter.vala
    Widgets/UserItem.vala
    Widgets/PasswordEditor.vala
    Widgets/CropView.vala
    Widgets/Popovers/NewUserPopover.vala
    Widgets/Popovers/PasswordPopover.vala
    Widgets/Popovers/AvatarPopover.vala
    ${CMAKE_CURRENT_BINARY_DIR}/config.vala
PACKAGES
    gtk+-3.0
    gee-0.8
    granite>=0.4.1
    AccountsService-1.0
    gnome-desktop-3.0
    posix
    polkit-gobject-1
    pwquality
    run-passwd
OPTIONS
    --thread
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
)

include_directories (${CMAKE_CURRENT_SOURCE_DIR}/../lib/)

#add_library (${CMAKE_PROJECT_NAME} MODULE ${VALA_C} ../lib/run-passwd.c)
#target_link_libraries (${CMAKE_PROJECT_NAME} ${DEPS_LIBRARIES}) 
add_definitions(${CFLAGS} -Wall -Winit-self -Wwrite-strings -Wunreachable-code -Wstrict-prototypes)
add_executable (${CMAKE_PROJECT_NAME} ${VALA_C} ../lib/run-passwd.c)
target_link_libraries (${CMAKE_PROJECT_NAME} m)

# Installation
install (TARGETS ${CMAKE_PROJECT_NAME} RUNTIME DESTINATION bin)
