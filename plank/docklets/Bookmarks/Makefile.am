include $(top_srcdir)/Makefile.common

VAPIDIR = $(top_srcdir)/vapi

libdocklet_bookmarks_la_LTLIBRARIES = libdocklet-bookmarks.la

libdocklet_bookmarks_ladir = $(pkglibdir)/docklets

libdocklet_bookmarks_la_VALASOURCES = \
	BookmarksDockItem.vala \
	BookmarksDocklet.vala \
	$(NULL)

nodist_libdocklet_bookmarks_la_SOURCES = \
	$(libdocklet_bookmarks_la_VALASOURCES:.vala=.c) \
	$(NULL)

libdocklet_bookmarks_la_VALAFLAGS = \
	$(PLANK_CORE_VALAFLAGS) \
	$(VAPIDIR)/config.vapi \
	--vapidir $(top_srcdir)/vapi \
	--vapidir $(top_builddir)/lib \
	--pkg plank \
	$(NULL)

libdocklet_bookmarks_la_LIBADD = \
	$(PLANK_CORE_LIBS) \
	$(NULL)

libdocklet_bookmarks_la_LDFLAGS = \
	$(DOCKLET_LDFLAGS) \
	$(PLANK_CORE_LDFLAGS) \
	$(top_builddir)/lib/libplank.la \
	$(NULL)

libdocklet_bookmarks_la_CFLAGS = \
	$(PLANK_CORE_CFLAGS) \
	-include config.h \
	-I$(top_builddir)/lib \
	$(NULL)

$(libdocklet_bookmarks_la_VALASOURCES:.vala=.c): libdocklet_bookmarks_la_vala.stamp

libdocklet_bookmarks_la_vala.stamp: $(libdocklet_bookmarks_la_VALASOURCES) $(top_builddir)/lib/plank.vapi Makefile
	$(AM_V_VALA)$(VALAC) \
		$(libdocklet_bookmarks_la_VALAFLAGS) \
		-C \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

CLEANFILES = \
	libdocklet_bookmarks_la_vala.stamp \
	$(nodist_libdocklet_bookmarks_la_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	$(libdocklet_bookmarks_la_VALASOURCES) \
	$(NULL)

