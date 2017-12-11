### CMakeLists automatically created with AutoVala
### Do not edit

set (DATADIR "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_DATAROOTDIR}")
set (PKGDATADIR "${DATADIR}/panther_launcher")
set (GETTEXT_PACKAGE "panther_launcher")
set (RELEASE_NAME "panther_launcher")
set (CMAKE_C_FLAGS "")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (VERSION "1.12.0")
set (TESTSRCDIR "${CMAKE_SOURCE_DIR}")
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/src/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
set (VERSION "1.12.0")
add_definitions (${DEPS_CFLAGS})
link_libraries ( ${DEPS_LIBRARIES} )
link_directories ( ${DEPS_LIBRARY_DIRS} )
find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.26" MINIMUM)
include (ValaPrecompile)

set (VALA_PACKAGES ${VALA_PACKAGES} posix)
if ((HAVE_ZEITGEIST))
	set (VALA_PACKAGES ${VALA_PACKAGES} zeitgeist-1.0)
endif ()
set (VALA_PACKAGES ${VALA_PACKAGES} atk)
set (VALA_PACKAGES ${VALA_PACKAGES} cairo)
set (VALA_PACKAGES ${VALA_PACKAGES} gdk-3.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gdk-pixbuf-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gee-0.8)
set (VALA_PACKAGES ${VALA_PACKAGES} gio-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gio-unix-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} glib-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gobject-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gtk+-3.0)
set (VALA_PACKAGES ${VALA_PACKAGES} json-glib-1.0)
set (VALA_PACKAGES ${VALA_PACKAGES} libgnome-menu-3.0)
set (VALA_PACKAGES ${VALA_PACKAGES} libsoup-2.4)
set (VALA_PACKAGES ${VALA_PACKAGES} pango)
set (VALA_PACKAGES ${VALA_PACKAGES} pangocairo)
set (VALA_PACKAGES ${VALA_PACKAGES} x11)
set (VALA_PACKAGES ${VALA_PACKAGES} plank)
#set (VALA_PACKAGES ${VALA_PACKAGES} exo-1)

#set (XFCE_VALA_PACKAGES ${XFCE_VALA_PACKAGES} libxfce4panel-2.0)
#set (XFCE_VALA_PACKAGES ${XFCE_VALA_PACKAGES} libxfconf-0)
#set (XFCE_VALA_PACKAGES ${XFCE_VALA_PACKAGES} garcon-1)
#set (XFCE_VALA_PACKAGES ${XFCE_VALA_PACKAGES} exo-1)
set (XFCE_VALA_PACKAGES ${XFCE_VALA_PACKAGES} gtk+-3.0)
set (XFCE_VALA_PACKAGES ${XFCE_VALA_PACKAGES} glib-2.0)

set (APP_SOURCES ${APP_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/Config.vala)
set (APP_SOURCES ${APP_SOURCES} Backend/App.vala)
set (APP_SOURCES ${APP_SOURCES} Backend/AppSystem.vala)
set (APP_SOURCES ${APP_SOURCES} Backend/DBusService.vala)
set (APP_SOURCES ${APP_SOURCES} Backend/RelevancyService.vala)
set (APP_SOURCES ${APP_SOURCES} Backend/SynapseSearch.vala)
set (APP_SOURCES ${APP_SOURCES} Backend/Plank.vala)
set (APP_SOURCES ${APP_SOURCES} Panther.vala)
set (APP_SOURCES ${APP_SOURCES} PantherView.vala)
set (APP_SOURCES ${APP_SOURCES} Pixels.vala)
set (APP_SOURCES ${APP_SOURCES} Settings.vala)
set (APP_SOURCES ${APP_SOURCES} Utils.vala)
set (APP_SOURCES ${APP_SOURCES} Widgets/AppEntry.vala)
set (APP_SOURCES ${APP_SOURCES} Widgets/CategoryView.vala)
set (APP_SOURCES ${APP_SOURCES} Widgets/Grid.vala)
set (APP_SOURCES ${APP_SOURCES} Widgets/SearchItem.vala)
set (APP_SOURCES ${APP_SOURCES} Widgets/SearchView.vala)
set (APP_SOURCES ${APP_SOURCES} Widgets/Sidebar.vala)
set (APP_SOURCES ${APP_SOURCES} Widgets/Switcher.vala)
set (APP_SOURCES ${APP_SOURCES} Widgets/UserView.vala)
set (APP_SOURCES ${APP_SOURCES} synapse-core/common-actions.vala)
set (APP_SOURCES ${APP_SOURCES} synapse-core/config-service.vala)
set (APP_SOURCES ${APP_SOURCES} synapse-core/data-sink.vala)
set (APP_SOURCES ${APP_SOURCES} synapse-core/dbus-service.vala)
set (APP_SOURCES ${APP_SOURCES} synapse-core/desktop-file-service.vala)
set (APP_SOURCES ${APP_SOURCES} synapse-core/match.vala)
set (APP_SOURCES ${APP_SOURCES} synapse-core/plugin.vala)
set (APP_SOURCES ${APP_SOURCES} synapse-core/query.vala)
set (APP_SOURCES ${APP_SOURCES} synapse-core/relevancy-backend-zg.vala)
set (APP_SOURCES ${APP_SOURCES} synapse-core/relevancy-service.vala)
set (APP_SOURCES ${APP_SOURCES} synapse-core/result-set.vala)
set (APP_SOURCES ${APP_SOURCES} synapse-core/utils.vala)
set (APP_SOURCES ${APP_SOURCES} synapse-core/volume-service.vala)
set (APP_SOURCES ${APP_SOURCES} synapse-plugins/calculator-plugin.vala)
set (APP_SOURCES ${APP_SOURCES} synapse-plugins/command-plugin.vala)
set (APP_SOURCES ${APP_SOURCES} synapse-plugins/desktop-file-plugin.vala)
set (APP_SOURCES ${APP_SOURCES} synapse-plugins/system-managment.vala)

if (HAVE_ZEITGEIST)
	set (COMPILE_OPTIONS ${COMPILE_OPTIONS} -D HAVE_ZEITGEIST)
	set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DHAVE_ZEITGEIST " )
	set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DHAVE_ZEITGEIST " )
endif ()
if (HAS_PLANK)
	set (COMPILE_OPTIONS ${COMPILE_OPTIONS} -D HAS_PLANK)
	set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DHAS_PLANK " )
	set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DHAS_PLANK " )
endif ()
if (DISABLE_FLASHBACK)
	set (COMPILE_OPTIONS ${COMPILE_OPTIONS} -D DISABLE_FLASHBACK)
	set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DDISABLE_FLASHBACK " )
	set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DDISABLE_FLASHBACK " )
endif ()
if (DISABLE_MATE)
	set (COMPILE_OPTIONS ${COMPILE_OPTIONS} -D DISABLE_MATE)
	set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DDISABLE_MATE " )
	set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DDISABLE_MATE " )
endif ()

if ((${CMAKE_BUILD_TYPE} STREQUAL "Debug") OR (${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo"))
	set(COMPILE_OPTIONS ${COMPILE_OPTIONS} "-g")
endif()

set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DGMENU_I_KNOW_THIS_IS_UNSTABLE" )

vala_precompile(VALA_C_XFCE pantherplugin
	Xfce4PantherPlugin.vala
PACKAGES
	${XFCE_VALA_PACKAGES}
CUSTOM_VAPIS
	${CMAKE_SOURCE_DIR}/vapi/garcon-1.vapi
	${CMAKE_SOURCE_DIR}/vapi/libxfce4panel-2.0.vapi
	${CMAKE_SOURCE_DIR}/vapi/libxfconf-0.vapi
OPTIONS

)

#add_executable(pantherplugin ${VALA_C})
add_library (pantherplugin SHARED
        ${VALA_C_XFCE}
    )

include_directories(${GTK+_INCLUDE_DIRS} ${XFCE_INCLUDE_DIRS})
target_link_libraries( pantherplugin ${GTK+_LIBRARIES} ${XFCE_LIBRARIES} -lm )

vala_precompile(VALA_C panther_launcher
	${APP_SOURCES}
PACKAGES
	${VALA_PACKAGES}
OPTIONS
	${COMPILE_OPTIONS}
)

add_executable(panther_launcher ${VALA_C})
target_link_libraries( panther_launcher m )

install(TARGETS
	pantherplugin
DESTINATION
	${CMAKE_INSTALL_LIBDIR}/xfce4/panel/plugins
)

install(TARGETS
	panther_launcher
RUNTIME DESTINATION
	${CMAKE_INSTALL_BINDIR}
)

if(HAVE_VALADOC)
	valadoc(panther_launcher
		${CMAKE_BINARY_DIR}/valadoc/panther_launcher
		${APP_SOURCES}
	PACKAGES
		${VALA_PACKAGES}
	CUSTOM_VAPIS
		${CUSTOM_VAPIS_LIST}
	)
	install(DIRECTORY
		${CMAKE_BINARY_DIR}/valadoc
	DESTINATION
		${CMAKE_INSTALL_DATAROOTDIR}/doc/panther_launcher
	)
endif()
