find_package (PkgConfig)

# Add all your dependencies to the list below
pkg_check_modules (DEPS REQUIRED gthread-2.0 gtk+-3.0 granite
  libecal-1.2 libical libsoup-2.4 libedataserver-1.2 libxfce4panel-2.0 libxfconf-0)

add_definitions (${DEPS_CFLAGS})
link_directories (${DEPS_LIBRARY_DIRS})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.40.3" MINIMUM)

include (ValaPrecompile)
# Add all your vala files and requires packages to the List below to include them in the build
vala_precompile (VALA_C ${CMAKE_PROJECT_NAME}
  XfcePanelPlug.vala
  Indicator.vala
  Widgets/PanelLabel.vala
  Widgets/calendar/Calendar.vala
  Widgets/calendar/CalendarModel.vala
  Widgets/calendar/CalendarView.vala
  Widgets/calendar/ControlHeader.vala
  Widgets/calendar/Util.vala
  Widgets/calendar/Grid.vala
  Widgets/calendar/GridDay.vala
  Widgets/calendar/Header.vala
  Widgets/calendar/WeekLabels.vala
  Services/TimeManager.vala
  Services/ClockSettings.vala
  Services/SettingsManager.vala
PACKAGES
  glib-2.0>=2.32
  granite
  libecalendar-1.2
  libedataserver-1.2
  libical
  libsoup-2.4
  libxfce4panel-2.0
  libxfconf-0
OPTIONS
  --target-glib=2.32
  --vapidir=${CMAKE_SOURCE_DIR}/vapi
  --gresources=${CMAKE_CURRENT_SOURCE_DIR}/css.gresource.xml
  --thread
)

include (GResource)
glib_compile_resources (GLIB_RESOURCES_CSS SOURCE css.gresource.xml)

add_library (${CMAKE_PROJECT_NAME} MODULE ${VALA_C} ${GLIB_RESOURCES_CSS})
target_link_libraries(${CMAKE_PROJECT_NAME} ${DEPS_LIBRARIES})

# Installation
# install (TARGETS ${CMAKE_PROJECT_NAME} DESTINATION ${PKGDATADIR})
install(TARGETS ${CMAKE_PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_LIBDIR}/xfce4/panel/plugins)
