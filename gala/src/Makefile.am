include $(top_srcdir)/Makefile.common

VAPIDIR = $(top_srcdir)/vapi

gala_VALAFLAGS = \
	$(GALA_CORE_VALAFLAGS) \
	$(top_builddir)/lib/gala.vapi \
	--vapidir $(VAPIDIR) \
	$(VAPIDIR)/config.vapi \
	$(VAPIDIR)/cogl-fixes.vapi \
	$(VAPIDIR)/compat.vapi \
	$(NULL)

galadir = $(bindir)

BUILT_SOURCES = gala_vala.stamp

gala_PROGRAMS = gala

gala_CFLAGS = \
	$(GALA_CORE_CFLAGS) \
	-include config.h \
	-w \
	-DGNOME_DESKTOP_USE_UNSTABLE_API \
	-I$(top_builddir)/lib \
	$(NULL)

gala_LDADD = \
	$(LIBM) \
	$(GALA_CORE_LIBS) \
	$(top_builddir)/lib/libgala.la \
	$(NULL)

gala_VALASOURCES = \
	DBus.vala \
	DBusAccelerator.vala \
	DockThemeManager.vala \
	DragDropAction.vala \
	InternalUtils.vala \
	KeyboardManager.vala \
	Main.vala \
	MediaFeedback.vala \
	PluginManager.vala \
	ScreenSaver.vala \
	ScreenshotManager.vala \
	Settings.vala \
	ShadowEffect.vala \
	TextShadowEffect.vala \
	WindowListener.vala \
	WindowManager.vala \
	WorkspaceManager.vala \
	Background/Animation.vala \
	Background/Background.vala \
	Background/BackgroundCache.vala \
	Background/BackgroundContainer.vala \
	Background/BackgroundManager.vala \
	Background/BackgroundSource.vala \
	Background/SystemBackground.vala \
	Widgets/IconGroup.vala \
	Widgets/IconGroupContainer.vala \
	Widgets/MonitorClone.vala \
	Widgets/MultitaskingView.vala \
	Widgets/SafeWindowClone.vala \
	Widgets/WindowClone.vala \
	Widgets/WindowCloneContainer.vala \
	Widgets/WindowIconActor.vala \
	Widgets/WindowMenu.vala \
	Widgets/WindowOverview.vala \
	Widgets/WindowSwitcher.vala \
	Widgets/WorkspaceClone.vala \
	Widgets/WorkspaceInsertThumb.vala \
	$(NULL)

nodist_gala_SOURCES = \
	gala_vala.stamp \
	$(gala_VALASOURCES:.vala=.c) \
	$(NULL)

gala_vala.stamp: $(gala_VALASOURCES) $(top_builddir)/lib/gala.vapi Makefile
	$(AM_V_VALA)$(VALAC) \
		$(gala_VALAFLAGS) \
		--basedir $(srcdir) \
		--directory $(builddir) \
		-C \
		$(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

CLEANFILES = \
	$(nodist_gala_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	$(gala_background) \
	$(gala_background312) \
	$(gala_VALASOURCES) \
	$(NULL)

