include $(top_srcdir)/Makefile.common

VAPIDIR = $(top_srcdir)/vapi

BUILT_SOURCES = \
	docky-separator-resources.c \
	$(NULL)

libdocklet_separator_la_LTLIBRARIES = libdocklet-separator.la

libdocklet_separator_ladir = $(pkglibdir)/docklets

libdocklet_separator_la_VALASOURCES = \
	SeparatorDockItem.vala \
	SeparatorDocklet.vala \
	$(NULL)

nodist_libdocklet_separator_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libdocklet_separator_la_VALASOURCES:.vala=.c) \
	$(NULL)

libdocklet_separator_la_VALAFLAGS = \
	$(PLANK_CORE_VALAFLAGS) \
	$(VAPIDIR)/config.vapi \
	--vapidir $(top_srcdir)/vapi \
	--vapidir $(top_builddir)/lib \
	--pkg plank \
	$(NULL)

libdocklet_separator_la_LIBADD = \
	$(PLANK_CORE_LIBS) \
	$(NULL)

libdocklet_separator_la_LDFLAGS = \
	$(DOCKLET_LDFLAGS) \
	$(PLANK_CORE_LDFLAGS) \
	$(top_builddir)/lib/libplank.la \
	$(NULL)

libdocklet_separator_la_CFLAGS = \
	$(PLANK_CORE_CFLAGS) \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	-include config.h \
	-I$(top_builddir)/lib \
	$(NULL)

docky-separator-resources.c: $(srcdir)/separator.gresource.xml Makefile $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir $(srcdir) $(srcdir)/separator.gresource.xml)
	$(AM_V_GEN) XMLLINT=$(XMLLINT) $(GLIB_COMPILE_RESOURCES) --target $@ --sourcedir $(srcdir) --generate --c-name docky_separator $<

$(libdocklet_separator_la_VALASOURCES:.vala=.c): libdocklet_separator_la_vala.stamp

libdocklet_separator_la_vala.stamp: $(libdocklet_separator_la_VALASOURCES) $(top_builddir)/lib/plank.vapi Makefile
	$(AM_V_VALA)$(VALAC) \
		$(libdocklet_separator_la_VALAFLAGS) \
		-C \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

CLEANFILES = \
	libdocklet_separator_la_vala.stamp \
	$(nodist_libdocklet_separator_la_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	$(libdocklet_separator_la_VALASOURCES) \
	separator.gresource.xml \
	icons/separator.svg \
	$(NULL)

