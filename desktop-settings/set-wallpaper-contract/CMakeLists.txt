set (EXEC_NAME "set-wallpaper")
set (SOURCES "set-wallpaper.vala")
set (SWEXECDIR "${CMAKE_INSTALL_FULL_LIBEXECDIR}/switchboard-plug-pantheon-shell")
set (DEPENDENCIES granite)

configure_file (set-wallpaper.contract.in ${CMAKE_CURRENT_BINARY_DIR}/set-wallpaper.contract)

find_package (PkgConfig)
pkg_check_modules (DEPS REQUIRED ${DEPENDENCIES})

vala_precompile (WALLPAPER_CONTRACT_VALA_C ${EXEC_NAME} ${SOURCES} PACKAGES ${DEPENDENCIES} posix)
add_executable (${EXEC_NAME} ${WALLPAPER_CONTRACT_VALA_C})

add_definitions (${DEPS_CFLAGS})
link_directories (${DEPS_LIBRARY_DIRS})
target_link_libraries (${EXEC_NAME} m ${DEPS_LIBRARIES})

install (TARGETS ${EXEC_NAME} DESTINATION ${SWEXECDIR})
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/set-wallpaper.contract DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/contractor)

