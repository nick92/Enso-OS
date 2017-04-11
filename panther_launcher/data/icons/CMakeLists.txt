### CMakeLists automatically created with AutoVala
### Do not edit

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/panther-categories-symbolic.svg DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/status/)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/panther-icons-symbolic.svg DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/status/)
if( NOT (${ICON_UPDATE} STREQUAL "OFF" ))
	find_program ( GTK_UPDATE_ICON_CACHE NAMES gtk-update-icon-cache.3.0 gtk-update-icon-cache )
	install (CODE "execute_process ( COMMAND ${GTK_UPDATE_ICON_CACHE} -f -t ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor )" )
ENDIF()
