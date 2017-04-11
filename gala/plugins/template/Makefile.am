include $(top_srcdir)/Makefile.common

VAPIDIR = $(top_srcdir)/vapi

BUILT_SOURCES = libgala_template_la_vala.stamp

libgala_template_la_LTLIBRARIES = libgala-template.la

libgala_template_ladir = $(pkglibdir)/plugins

libgala_template_la_LDFLAGS = \
	$(PLUGIN_LDFLAGS) \
	$(GALA_CORE_LDFLAGS) \
	$(top_builddir)/lib/libgala.la \
	$(NULL)

libgala_template_la_CFLAGS = \
	$(GALA_CORE_CFLAGS) \
	-include config.h \
	-w \
	-I$(top_builddir)/lib \
	$(NULL)

libgala_template_la_VALAFLAGS = \
	$(GALA_CORE_VALAFLAGS) \
	$(top_builddir)/lib/gala.vapi \
	--vapidir $(VAPIDIR) \
	$(VAPIDIR)/config.vapi \
	$(NULL)

libgala_template_la_LIBADD = \
	$(GALA_CORE_LIBS) \
	$(NULL)

libgala_template_la_VALASOURCES = \
	Main.vala \
	$(NULL)

nodist_libgala_template_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libgala_template_la_VALASOURCES:.vala=.c) \
	$(NULL)

libgala_template_la_vala.stamp: $(libgala_template_la_VALASOURCES) $(top_builddir)/lib/gala.vapi Makefile
	$(AM_V_VALA)$(VALAC) \
		$(libgala_template_la_VALAFLAGS) \
		-C \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

CLEANFILES = \
	$(nodist_libgala_template_la_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	$(libgala_template_la_VALASOURCES) \
	$(NULL)

