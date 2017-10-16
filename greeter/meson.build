project ('greeter', ['vala', 'c'])

add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')

glib = dependency ('glib-2.0')
gtk = dependency ('gtk+-3.0')
lightdm = dependency ('liblightdm-gobject-1')
gtkx11 = dependency ('gdk-x11-3.0')
clutter = dependency ('clutter-1.0')
x11 = dependency ('x11')
cluttergtk = dependency ('clutter-gtk-1.0')
gtkpixbuf = dependency ('gdk-pixbuf-2.0')
gee = dependency ('gee-0.8')
gl = dependency ('gl')

subdir ('data')
subdir ('src')
