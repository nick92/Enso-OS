include $(top_srcdir)/Makefile.common

VAPIDIR = $(top_srcdir)/vapi

imagedir = $(pkgdatadir)
dist_image_DATA = data/image-mask.svg

BUILT_SOURCES = libgala_notify_la_vala.stamp

libgala_notify_la_LTLIBRARIES = libgala-notify.la

libgala_notify_ladir = $(pkglibdir)/plugins

libgala_notify_la_LDFLAGS = \
	$(PLUGIN_LDFLAGS) \
	$(GALA_CORE_LDFLAGS) \
	$(NOTIFICATION_PLUGIN_LDFLAGS) \
	$(top_builddir)/lib/libgala.la \
	$(NULL)

libgala_notify_la_CFLAGS = \
	$(GALA_CORE_CFLAGS) \
	$(NOTIFICATION_PLUGIN_CFLAGS) \
	-include config.h \
	-w \
	-I$(top_builddir)/lib \
	$(NULL)

libgala_notify_la_VALAFLAGS = \
	$(GALA_CORE_VALAFLAGS) \
	$(NOTIFICATION_PLUGIN_VALA_PKGS) \
	$(top_builddir)/lib/gala.vapi \
	--vapidir $(VAPIDIR) \
	$(VAPIDIR)/config.vapi \
	$(NULL)

libgala_notify_la_LIBADD = \
	$(GALA_CORE_LIBS) \
	$(NOTIFICATION_PLUGIN_LIBS) \
	$(NULL)

libgala_notify_la_VALASOURCES = \
	Main.vala \
	ConfirmationNotification.vala \
	NormalNotification.vala \
	Notification.vala \
	NotificationStack.vala \
	NotifyServer.vala \
	NotifySettings.vala \
	$(NULL)

nodist_libgala_notify_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libgala_notify_la_VALASOURCES:.vala=.c) \
	$(NULL)

libgala_notify_la_vala.stamp: $(libgala_notify_la_VALASOURCES) $(top_builddir)/lib/gala.vapi Makefile
	$(AM_V_VALA)$(VALAC) \
		$(libgala_notify_la_VALAFLAGS) \
		-C \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

CLEANFILES = \
	$(nodist_libgala_notify_la_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	$(libgala_notify_la_VALASOURCES) \
	$(NULL)
