cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.8)

# Set the Properties of your Plug

# Set the Name of the plug, should be an executable command, lowercase, no spaces 
set (PLUGNAME "desktop-settings")
# Set the Category of the Plug, one of:
# personal, hardware, network, system
set (PLUGCATEGORY "personal")
# Set the Title to use for the Plug in the Overview and in the Titlebar
set (PLUGTITLE "Desktop")
# The symbolic name of the Icon to use for the plug
set (PLUGICON "preferences-desktop-wallpaper")
# Set the version for the plug
set (VERSION "1.0.1")

project (${PLUGNAME} C)

include (GNUInstallDirs)
#set (DATADIR ${CMAKE_INSTALL_FULL_LIBDIR}/switchboard)
set (PLANKDATADIR ${CMAKE_INSTALL_FULL_DATADIR}/plank)
#set (PKGDATADIR ${DATADIR}/${PLUGCATEGORY}/${PLUGNAME})
set (GETTEXT_PACKAGE ${PLUGNAME}-plug)

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/enso/greeter")
set (CMAKE_INSTALL_PREFIX /usr)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Comment this out to enable C compiler warnings
add_definitions (-w)
add_definitions (-DGNOME_DESKTOP_USE_UNSTABLE_API)

# Configure file
configure_file (${CMAKE_SOURCE_DIR}/config.vala.cmake ${CMAKE_BINARY_DIR}/src/config.vala)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# Add 'make dist' command for creating release tarball
set (CPACK_PACKAGE_VERSION ${VERSION})
set (CPACK_SOURCE_GENERATOR "TGZ")
set (CPACK_SOURCE_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-${CPACK_PACKAGE_VERSION}")
set (CPACK_SOURCE_IGNORE_FILES "/build/;/.bzr/;/.bzrignore;~$;${CPACK_SOURCE_IGNORE_FILES}")
include (CPack)
add_custom_target (dist COMMAND ${CMAKE_MAKE_PROGRAM} package_source)

# Files
file (GLOB resources ${CMAKE_CURRENT_SOURCE_DIR}/data/*.svg)

# Traslation stuff
add_subdirectory (po)

add_subdirectory(src)
add_subdirectory(set-wallpaper-contract)

# install desktop file
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/desktop-settings.desktop DESTINATION ${CMAKE_INSTALL_PREFIX}/share/applications/)
