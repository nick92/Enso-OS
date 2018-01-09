project (greeter)
cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.8)

enable_testing ()

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

set (CONF_DIR "/etc/lightdm")
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/enso/greeter")
set (CMAKE_INSTALL_PREFIX /usr)
set (VERSION "1.0.6")


configure_file (${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_BINARY_DIR}/src/config.vala)
add_definitions (-DGETTEXT_PACKAGE="greeter")

# Comment this out to enable C compiler warnings
add_definitions (-w)

# Add 'make dist' command for creating release tarball
set (CPACK_PACKAGE_VERSION ${VERSION})
set (CPACK_SOURCE_GENERATOR "TGZ")
set (CPACK_SOURCE_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-${CPACK_PACKAGE_VERSION}")
set (CPACK_SOURCE_IGNORE_FILES "/build/;/.bzr/;/.bzrignore;~$;${CPACK_SOURCE_IGNORE_FILES}")

include (CPack)
add_custom_target (dist COMMAND ${CMAKE_MAKE_PROGRAM} package_source)

find_package (PkgConfig)
pkg_check_modules (DEPS REQUIRED gee-0.8 liblightdm-gobject-1>=1.2.1 gdk-x11-3.0 clutter-gtk-1.0 gdk-pixbuf-2.0 gl)
add_definitions (${DEPS_CFLAGS})
link_libraries (${DEPS_LIBRARIES})
link_directories (${DEPS_LIBRARY_DIRS})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.26.0" MINIMUM)

include (ValaPrecompile)
vala_precompile (VALA_C
    src/PantheonGreeter.vala
    src/SettingsDaemon.vala
    src/UserList.vala
    src/UserListActor.vala

    src/Gateways/DummyGateway.vala
    src/Gateways/LightDMGateway.vala
    src/Gateways/LoginGateway.vala

    src/Interfaces/Credentials.vala
    src/Interfaces/LoginMask.vala

    src/LoginOptions/GuestLogin.vala
    src/LoginOptions/LoginOption.vala
    src/LoginOptions/ManualLogin.vala
    src/LoginOptions/UserLogin.vala

    src/Widgets/CredentialsArea.vala
    src/Widgets/DeepinBlurEffect.vala
    src/Widgets/FingerprintCredentials.vala
    src/Widgets/LoginBox.vala
    src/Widgets/LoginButtonCredentials.vala
    src/Widgets/PasswordCredentials.vala
    src/Widgets/TimeLabel.vala
    src/Widgets/PowerLabel.vala
    src/Widgets/Wallpaper.vala
    src/Widgets/Avatar.vala

    ${CMAKE_BINARY_DIR}/src/config.vala
PACKAGES
    gee-0.8
    liblightdm-gobject-1
    posix
    gdk-pixbuf-2.0
    gdk-x11-3.0
    x11
    clutter-gtk-1.0
    gl
CUSTOM_VAPIS
	vapi/cogl-fixes.vapi
OPTIONS
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi
)

add_subdirectory (po)

include (GSettings)

include (GResource)
glib_compile_resources (GLIB_RESOURCES_CSS SOURCE data/css.gresource.xml)

add_executable (pantheon-greeter ${VALA_C} ${GLIB_RESOURCES_CSS})
target_link_libraries(pantheon-greeter m)

install (TARGETS pantheon-greeter RUNTIME DESTINATION sbin)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/pantheon-greeter.desktop DESTINATION share/xgreeters)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/greeter.conf DESTINATION ${CONF_DIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/fingerprint.svg DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/power.svg DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/checked.svg DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/shader.glsl DESTINATION ${PKGDATADIR})
