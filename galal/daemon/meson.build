gala_daemon_sources = files(
	'Main.vala',
	'MenuDaemon.vala'
)

gala_daemon_bin = executable(
	'gala-daemon',
	gala_daemon_sources,
	dependencies: [gala_dep, gala_base_dep],
	install: true,
)
