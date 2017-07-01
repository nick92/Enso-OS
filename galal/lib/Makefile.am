include $(top_srcdir)/Makefile.common

VAPIDIR = $(top_srcdir)/vapi

BUILT_SOURCES = \
	libgala_la_vala.stamp \
	$(NULL)

libgalaincludedir = $(includedir)/gala
nodist_libgalainclude_HEADERS = gala.h

vapidir = $(datadir)/vala/vapi
nodist_vapi_DATA = \
	gala.vapi \
	gala.deps \
	$(NULL)

pkgconfigdir = $(libdir)/pkgconfig
nodist_pkgconfig_DATA = gala.pc


lib_LTLIBRARIES = libgala.la

libgala_la_CFLAGS = \
	$(GALA_CORE_CFLAGS) \
	-include config.h \
	-w \
	$(NULL)

libgala_la_LDFLAGS = \
	$(AM_LDLAGS) \
	$(GALA_CORE_LDFLAGS) \
	-no-undefined \
	-version-info "$(LT_CURRENT)":"$(LT_REVISION)":"$(LT_AGE)" \
	-export-dynamic \
	-export-symbols-regex '^gala_.*' \
	$(NULL)

libgala_la_VALAFLAGS = \
	$(GALA_CORE_VALAFLAGS) \
	--vapidir $(VAPIDIR) \
	$(VAPIDIR)/config.vapi \
	$(NULL)

libgala_la_LIBADD = \
	$(GALA_CORE_LIBS) \
	$(NULL)

libgala_la_VALASOURCES = \
	ActivatableComponent.vala \
	Plugin.vala \
	Utils.vala \
	WindowIcon.vala \
	WindowManager.vala \
	$(NULL)

nodist_libgala_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libgala_la_VALASOURCES:.vala=.c) \
	$(NULL)

gala.h gala.vapi: libgala_la_vala.stamp

libgala_la_vala.stamp: $(libgala_la_VALASOURCES) Makefile
	$(AM_V_VALA)$(VALAC) \
		$(libgala_la_VALAFLAGS) \
		--basedir $(srcdir) \
		--directory $(builddir) \
		-C \
		-H gala.h \
		--vapi gala.vapi \
		--library gala \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

CLEANFILES = \
	$(nodist_libgala_la_SOURCES) \
	gala.vapi \
	gala.h \
	$(NULL)

EXTRA_DIST = \
	$(libgala_la_VALASOURCES) \
	gala.deps \
	$(NULL)

