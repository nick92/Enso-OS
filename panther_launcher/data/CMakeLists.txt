### CMakeLists automatically created with AutoVala
### Do not edit

SET(DBUS_PREFIX ${CMAKE_INSTALL_PREFIX})
IF(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/panther-applications.menu)
	install(DIRECTORY
		${CMAKE_CURRENT_SOURCE_DIR}/panther-applications.menu
	DESTINATION
		/etc/xdg/menus
	)
ELSE()
	install(FILES
		${CMAKE_CURRENT_SOURCE_DIR}/panther-applications.menu
	DESTINATION
		/etc/xdg/menus
	)
ENDIF()

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/panther-launcher.desktop DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/xfce4/panel/plugins/)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/com.rastersoft.panther.remotecontrol.service ${CMAKE_CURRENT_BINARY_DIR}/com.rastersoft.panther.remotecontrol.service)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/com.rastersoft.panther.remotecontrol.service DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/dbus-1/services/)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/com.rastersoft.panther.remotecontrol.service.base ${CMAKE_CURRENT_BINARY_DIR}/com.rastersoft.panther.remotecontrol.service)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/com.rastersoft.panther.remotecontrol.service DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/dbus-1/services/)
include(GSettings)
add_schema(org.rastersoft.panther.gschema.xml)
