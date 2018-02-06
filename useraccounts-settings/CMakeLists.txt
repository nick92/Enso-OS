cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.8)

# Set the Category of the Plug, one of:
# personal, hardware, network, system
set (PLUGCATEGORY "system")
# Set the Name of the plug, should be an executable command, lowercase, no spaces 
set (PLUGNAME "useraccount-settings")
# Set the Title to use for the Plug in the Overview and in the Titlebar
set (PLUGTITLE "User Accounts")
# Set the version for the plug
set (VERSION "0.1.6")

# Set the Name of the plug, should be an executable command, lowercase, no spaces 
project (${PLUGNAME} C)

                                                        #
# Only alter stuff below if you know what you are doing #
                                                        #

include (GNUInstallDirs)
#set (DATADIR "${CMAKE_INSTALL_FULL_LIBDIR}/switchboard")
set (PKGDATADIR "${DATADIR}/${PLUGCATEGORY}/pantheon-${PLUGNAME}")
set (GETTEXT_PACKAGE "${CMAKE_PROJECT_NAME}-plug")

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
#set (PKGDATADIR "${DATADIR}/enso/greeter")
#set (CMAKE_INSTALL_PREFIX /usr)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Configure file
configure_file (${CMAKE_SOURCE_DIR}/config.vala.cmake ${CMAKE_BINARY_DIR}/src/config.vala)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# Files
file (GLOB resources "${CMAKE_CURRENT_SOURCE_DIR}/data/*")

configure_file (${CMAKE_SOURCE_DIR}/data/org.pantheon.switchboard.user-accounts.policy.cmake ${CMAKE_BINARY_DIR}/data/org.pantheon.switchboard.user-accounts.policy)
install (FILES ${CMAKE_BINARY_DIR}/data/org.pantheon.switchboard.user-accounts.policy DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/polkit-1/actions/)

install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/useraccount-settings.desktop DESTINATION ${DATADIR}/applications/)

# Traslation stuff
add_subdirectory (po)

# Comment this out to enable C compiler warnings
add_definitions (-w)

add_subdirectory (src)
#add_subdirectory (cli)
