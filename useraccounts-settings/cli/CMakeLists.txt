find_package (PkgConfig)

# Add all your dependencies to the list below
pkg_check_modules (CLI_DEPS REQUIRED glib-2.0 gio-2.0)
add_definitions (${CLI_DEPS_CFLAGS})
link_directories (${CLI_DEPS_LIBRARY_DIRS})

set (CLI_EXEC_NAME guest-session-toggle)

vala_precompile (CLI_VALA_C ${CLI_EXEC_NAME}
	GuestSessionToggle.vala
PACKAGES
	glib-2.0
	gio-2.0
	posix
)

add_executable(${CLI_EXEC_NAME} ${CLI_VALA_C})
target_link_libraries (${CLI_EXEC_NAME} ${CLI_DEPS_LIBRARIES})

install (TARGETS ${CLI_EXEC_NAME} DESTINATION ${PKGDATADIR})
