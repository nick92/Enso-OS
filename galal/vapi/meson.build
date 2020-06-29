vapigen_args = [
	'--directory=@0@'.format(meson.current_build_dir()),
	'--metadatadir=@0@'.format(meson.current_source_dir()),
	'--girdir=@0@'.format(mutter_typelib_dir),
	'--vapidir=@0@'.format(meson.current_build_dir()),
	'--vapidir=@0@'.format(meson.current_source_dir()),
]

if mutter328_dep.found()
	cogl_target = custom_target('mutter-cogl-2',
		command: [
			vapigen,
			mutter_typelib_dir / 'Cogl-2.gir',
			'--library=mutter-cogl-2',
			'--pkg=gobject-2.0',
			vapigen_args,
			files('Cogl-2-custom.vala')
		],
		output: 'mutter-cogl-2.vapi'
	)

	cogl_pango_target = custom_target('mutter-cogl-pango-2',
		command: [
			vapigen,
			mutter_typelib_dir / 'CoglPango-2.gir',
			'--library=mutter-cogl-pango-2',
			'--pkg=mutter-cogl-2',
			'--pkg=pangocairo',
			vapigen_args
		],
		depends: cogl_target,
		output: 'mutter-cogl-pango-2.vapi'
	)

	clutter_target = custom_target('mutter-clutter-2',
		command: [
			vapigen,
			mutter_typelib_dir / 'Clutter-2.gir',
			'--library=mutter-clutter-2',
			'--pkg=mutter-cogl-2',
			'--pkg=mutter-cogl-pango-2',
			'--pkg=atk',
			'--pkg=gio-2.0',
			'--pkg=json-glib-1.0',
			'--pkg=pangocairo',
			vapigen_args,
			files('Clutter-2-custom.vala')
		],
		depends: [ cogl_target, cogl_pango_target ],
		output: 'mutter-clutter-2.vapi'
	)

	libmutter_target = custom_target('libmutter-2',
		command: [
			vapigen,
			mutter_typelib_dir / 'Meta-2.gir',
			'--library=libmutter-2',
			'--pkg=mutter-cogl-2',
			'--pkg=mutter-cogl-pango-2',
			'--pkg=mutter-clutter-2',
			'--pkg=atk',
			'--pkg=gio-2.0',
			'--pkg=json-glib-1.0',
			'--pkg=pangocairo',
			'--pkg=gtk+-3.0',
			'--pkg=x11',
			vapigen_args
		],
		depends: [ cogl_target, cogl_pango_target, clutter_target ],
		output: 'libmutter-2.vapi'
	)
endif
if mutter330_dep.found()
	cogl_target = custom_target('mutter-cogl-3',
		command: [
			vapigen,
			mutter_typelib_dir / 'Cogl-3.gir',
			'--library=mutter-cogl-3',
			'--pkg=gobject-2.0',
			vapigen_args,
			files('Cogl-3-custom.vala')
		],
		output: 'mutter-cogl-3.vapi'
	)

	cogl_pango_target = custom_target('mutter-cogl-pango-3',
		command: [
			vapigen,
			mutter_typelib_dir / 'CoglPango-3.gir',
			'--library=mutter-cogl-pango-3',
			'--pkg=mutter-cogl-3',
			'--pkg=pangocairo',
			vapigen_args
		],
		depends: cogl_target,
		output: 'mutter-cogl-pango-3.vapi'
	)

	clutter_target = custom_target('mutter-clutter-3',
		command: [
			vapigen,
			mutter_typelib_dir / 'Clutter-3.gir',
			'--library=mutter-clutter-3',
			'--pkg=mutter-cogl-3',
			'--pkg=mutter-cogl-pango-3',
			'--pkg=atk',
			'--pkg=gio-2.0',
			'--pkg=json-glib-1.0',
			'--pkg=pangocairo',
			vapigen_args,
			files('Clutter-3-custom.vala')
		],
		depends: [ cogl_target, cogl_pango_target ],
		output: 'mutter-clutter-3.vapi'
	)

	libmutter_target = custom_target('libmutter-3',
		command: [
			vapigen,
			mutter_typelib_dir / 'Meta-3.gir',
			'--library=libmutter-3',
			'--pkg=mutter-cogl-3',
			'--pkg=mutter-cogl-pango-3',
			'--pkg=mutter-clutter-3',
			'--pkg=atk',
			'--pkg=gio-2.0',
			'--pkg=json-glib-1.0',
			'--pkg=pangocairo',
			'--pkg=gtk+-3.0',
			'--pkg=x11',
			vapigen_args
		],
		depends: [ cogl_target, cogl_pango_target, clutter_target ],
		output: 'libmutter-3.vapi'
	)
endif
if mutter332_dep.found()
	cogl_target = custom_target('mutter-cogl-4',
		command: [
			vapigen,
			mutter_typelib_dir / 'Cogl-4.gir',
			'--library=mutter-cogl-4',
			'--pkg=gobject-2.0',
			vapigen_args,
			files('Cogl-4-custom.vala')
		],
		output: 'mutter-cogl-4.vapi'
	)

	cogl_pango_target = custom_target('mutter-cogl-pango-4',
		command: [
			vapigen,
			mutter_typelib_dir / 'CoglPango-4.gir',
			'--library=mutter-cogl-pango-4',
			'--pkg=mutter-cogl-4',
			'--pkg=pangocairo',
			vapigen_args
		],
		depends: cogl_target,
		output: 'mutter-cogl-pango-4.vapi'
	)

	clutter_target = custom_target('mutter-clutter-4',
		command: [
			vapigen,
			mutter_typelib_dir / 'Clutter-4.gir',
			'--library=mutter-clutter-4',
			'--pkg=mutter-cogl-4',
			'--pkg=mutter-cogl-pango-4',
			'--pkg=atk',
			'--pkg=gio-2.0',
			'--pkg=json-glib-1.0',
			'--pkg=pangocairo',
			vapigen_args,
			files('Clutter-4-custom.vala')
		],
		depends: [ cogl_target, cogl_pango_target ],
		output: 'mutter-clutter-4.vapi'
	)

	libmutter_target = custom_target('libmutter-4',
		command: [
			vapigen,
			mutter_typelib_dir / 'Meta-4.gir',
			'--library=libmutter-4',
			'--pkg=mutter-cogl-4',
			'--pkg=mutter-cogl-pango-4',
			'--pkg=mutter-clutter-4',
			'--pkg=atk',
			'--pkg=gio-2.0',
			'--pkg=json-glib-1.0',
			'--pkg=pangocairo',
			'--pkg=gtk+-3.0',
			'--pkg=x11',
			vapigen_args
		],
		depends: [ cogl_target, cogl_pango_target, clutter_target ],
		output: 'libmutter-4.vapi'
	)
endif
if mutter334_dep.found()
	cogl_target = custom_target('mutter-cogl-5',
		command: [
			vapigen,
			mutter_typelib_dir / 'Cogl-5.gir',
			'--library=mutter-cogl-5',
			'--pkg=gobject-2.0',
			vapigen_args,
			files('Cogl-5-custom.vala')
		],
		output: 'mutter-cogl-5.vapi'
	)

	cogl_pango_target = custom_target('mutter-cogl-pango-5',
		command: [
			vapigen,
			mutter_typelib_dir / 'CoglPango-5.gir',
			'--library=mutter-cogl-pango-5',
			'--pkg=mutter-cogl-5',
			'--pkg=pangocairo',
			vapigen_args
		],
		depends: cogl_target,
		output: 'mutter-cogl-pango-5.vapi'
	)

	clutter_target = custom_target('mutter-clutter-5',
		command: [
			vapigen,
			mutter_typelib_dir / 'Clutter-5.gir',
			'--library=mutter-clutter-5',
			'--pkg=mutter-cogl-5',
			'--pkg=mutter-cogl-pango-5',
			'--pkg=atk',
			'--pkg=gio-2.0',
			'--pkg=json-glib-1.0',
			'--pkg=pangocairo',
			vapigen_args,
			files('Clutter-5-custom.vala')
		],
		depends: [ cogl_target, cogl_pango_target ],
		output: 'mutter-clutter-5.vapi'
	)

	libmutter_target = custom_target('libmutter-5',
		command: [
			vapigen,
			mutter_typelib_dir / 'Meta-5.gir',
			'--library=libmutter-5',
			'--pkg=mutter-cogl-5',
			'--pkg=mutter-cogl-pango-5',
			'--pkg=mutter-clutter-5',
			'--pkg=atk',
			'--pkg=gio-2.0',
			'--pkg=json-glib-1.0',
			'--pkg=pangocairo',
			'--pkg=gtk+-3.0',
			'--pkg=x11',
			vapigen_args
		],
		depends: [ cogl_target, cogl_pango_target, clutter_target ],
		output: 'libmutter-5.vapi'
	)
endif
if mutter336_dep.found()
	cogl_target = custom_target('mutter-cogl-6',
		command: [
			vapigen,
			mutter_typelib_dir / 'Cogl-6.gir',
			'--library=mutter-cogl-6',
			'--pkg=mutter-cogl-path-6',
			'--pkg=gobject-2.0',
			'--pkg=cairo',
			'--pkg=graphene-gobject-1.0',
			vapigen_args,
			files('Cogl-6-custom.vala')
		],
		output: 'mutter-cogl-6.vapi'
	)

	cogl_pango_target = custom_target('mutter-cogl-pango-6',
		command: [
			vapigen,
			mutter_typelib_dir / 'CoglPango-6.gir',
			'--library=mutter-cogl-pango-6',
			'--pkg=mutter-cogl-path-6',
			'--pkg=mutter-cogl-6',
			'--pkg=pangocairo',
			vapigen_args
		],
		depends: cogl_target,
		output: 'mutter-cogl-pango-6.vapi'
	)

	clutter_target = custom_target('mutter-clutter-6',
		command: [
			vapigen,
			mutter_typelib_dir / 'Clutter-6.gir',
			'--library=mutter-clutter-6',
			'--pkg=graphene-gobject-1.0',
			'--pkg=mutter-cogl-6',
			'--pkg=mutter-cogl-pango-6',
			'--pkg=mutter-cogl-path-6',
			'--pkg=atk',
			'--pkg=gio-2.0',
			'--pkg=json-glib-1.0',
			'--pkg=pangocairo',
			vapigen_args,
			files('Clutter-6-custom.vala')
		],
		depends: [ cogl_target, cogl_pango_target ],
		output: 'mutter-clutter-6.vapi'
	)

	libmutter_target = custom_target('libmutter-6',
		command: [
			vapigen,
			mutter_typelib_dir / 'Meta-6.gir',
			'--library=libmutter-6',
			'--pkg=graphene-gobject-1.0',
			'--pkg=mutter-cogl-6',
			'--pkg=mutter-cogl-pango-6',
			'--pkg=mutter-cogl-path-6',
			'--pkg=mutter-clutter-6',
			'--pkg=atk',
			'--pkg=gio-2.0',
			'--pkg=json-glib-1.0',
			'--pkg=pangocairo',
			'--pkg=gtk+-3.0',
			'--pkg=x11',
			'--pkg=xfixes-4.0',
			vapigen_args
		],
		depends: [ cogl_target, cogl_pango_target, clutter_target ],
		output: 'libmutter-6.vapi'
	)
endif
