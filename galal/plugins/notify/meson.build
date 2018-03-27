gala_notify_sources = [
	'Main.vala',
	'ConfirmationNotification.vala',
	'NormalNotification.vala',
	'Notification.vala',
	'NotificationStack.vala',
	'NotifyServer.vala',
	'NotifySettings.vala',
]

canberra_dep = [dependency('libcanberra'), dependency('libcanberra-gtk3')]

gala_notify_lib = shared_library(
	'gala-notify',
	gala_notify_sources,
	dependencies: [gala_dep, gala_base_dep, canberra_dep],
	include_directories: config_inc_dir,
	install: true,
	install_dir: plugins_dir,
	install_rpath: mutter_typelib_dir,
)

install_data(
	'data/image-mask.svg',
	install_dir: pkgdata_dir,
)
