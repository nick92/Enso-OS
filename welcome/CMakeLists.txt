project (enso-welcome)
cmake_minimum_required (VERSION 2.8)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/vala)

#
# Base
#
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/${CMAKE_PROJECT_NAME}")
set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
set (EXEC_NAME ${CMAKE_PROJECT_NAME})
set (RELEASE_NAME "Welcome screen.")
set (VERSION "1.0.0")
set (VERSION_INFO "Beta")

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

#
# Niceties
#
set (ARCHIVE_NAME agenda-${VERSION})
add_custom_target (dist
    COMMAND bzr export --root=${ARCHIVE_NAME} ${CMAKE_BINARY_DIR}/${ARCHIVE_NAME}.tar.bz2
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

add_custom_target (distcheck
    COMMAND cd ${CMAKE_BINARY_DIR}
    && rm -rf ${ARCHIVE_NAME}
    && tar xf ${ARCHIVE_NAME}.tar.bz2
    && mkdir ${ARCHIVE_NAME}/build
    && cd ${ARCHIVE_NAME}/build
    && cmake -DCMAKE_INSTALL_PREFIX=../install -DGSETTINGS_LOCALINSTALL=ON .. -DCMAKE_MODULE_PATH=/usr/share/cmake
    && make -j8
    && make -j8 install
    && make check
)
add_dependencies (distcheck dist)

add_custom_target (uninstall "${CMAKE_COMMAND}" -P
    "${CMAKE_SOURCE_DIR}/cmake/uninstall.cmake")

#
# config.h
#
configure_file (${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h)
add_definitions(-include config.h)

#
# i18n
#
#add_subdirectory(po)

#
# dconf
#
include(GSettings)
add_schema(data/org.enso.welcome.gschema.xml)

# Suppress c Warnings
add_definitions(-w)

#
# Agenda
#
find_package(PkgConfig)

pkg_check_modules(DEPS REQUIRED
        gtk+-3.0>=3.16
        granite>=0.5
        glib-2.0>=2.39)

add_definitions(${DEPS_CFLAGS})

link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)

include(ValaVersion)
ensure_vala_version("0.28.0" MINIMUM)

include(ValaPrecompile)
vala_precompile(VALA_C
        src/Welcome.vala
        src/WelcomeWindow.vala
        src/View/WelcomeView.vala
        src/View/OptionsView.vala
        src/View/FlowBoxItem.vala
PACKAGES
        gtk+-3.0
        granite
        glib-2.0
CUSTOM_VAPIS
        vapi/config.vapi
OPTIONS
        --thread
)

include (GResource)
glib_compile_resources (GLIB_RESOURCES_CSS SOURCE data/css.gresource.xml)

add_definitions(${CFLAGS} -Wall -Winit-self -Wwrite-strings -Wunreachable-code -Wstrict-prototypes)
add_executable(${EXEC_NAME} ${VALA_C} ${GLIB_RESOURCES_CSS})

install (TARGETS enso-welcome RUNTIME DESTINATION bin)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/enso-welcome.desktop DESTINATION share/applications)
#install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/com.github.dahenson.agenda.svg DESTINATION share/icons/hicolor/16x16/apps)

option (ICON_UPDATE "Run gtk-update-icon-cache after the install." ON)
if (ICON_UPDATE)
  install (CODE "message(\"-- Updating icon cache...\")")
  install (CODE "execute_process(COMMAND gtk-update-icon-cache -f -t ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)")
endif (ICON_UPDATE)
