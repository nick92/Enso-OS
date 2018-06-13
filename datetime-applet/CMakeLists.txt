# This a sample CMakeLists.txt for compiling indicatos for Wingpanel
# http://elementaryos.org/docs/developer-guide/cmake 

cmake_minimum_required (VERSION 2.6)
cmake_policy (VERSION 2.6)

# Set the Title to use for the Indicator (May be used in future features)
set (INDICATORTITLE "Date & Time")

# The description of what your Indicator is
set (INDICATORDESCRIPTION "Date and Time indicator")

# Projectname
project (ensodatetime)

#########################################################
# Only alter stuff below if you know what you are doing #
#########################################################

# Configuration
include (GNUInstallDirs)
set (DATADIR "${CMAKE_INSTALL_FULL_LIBDIR}/wingpanel")
set (PKGDATADIR "${DATADIR}")
set (GETTEXT_PACKAGE "${CMAKE_PROJECT_NAME}-indicator")
set (VERSION "2.0.2")
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Configure file
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# Comment this out to enable C compiler warnings
add_definitions (-w)

# Files
file (GLOB resources "${CMAKE_CURRENT_SOURCE_DIR}/data/*")

# Traslation stuff
add_subdirectory (po)

# GSettings schema
add_subdirectory (schemas)

# Code
add_subdirectory(src)

# Data
add_subdirectory(data)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/ensodatetime.desktop DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/xfce4/panel/plugins)

# Uninstall target
configure_file(
  "${CMAKE_SOURCE_DIR}/cmake/Uninstall.cmake"
  "${CMAKE_CURRENT_BINARY_DIR}/Uninstall.cmake"
  IMMEDIATE @ONLY)

add_custom_target(uninstall
  COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/Uninstall.cmake)
