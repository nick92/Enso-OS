include $(top_srcdir)/Makefile.common

libgala_doc_files = \
	$(top_srcdir)/lib/ActivatableComponent.vala \
	$(top_srcdir)/lib/Plugin.vala \
	$(top_srcdir)/lib/Utils.vala \
	$(top_srcdir)/lib/WindowManager.vala \
	$(top_srcdir)/lib/WindowIcon.vala \
	$(NULL)

gala_doc_files = \
	$(top_srcdir)/src/DBus.vala \
	$(top_srcdir)/src/DockThemeManager.vala \
	$(top_srcdir)/src/DragDropAction.vala \
	$(top_srcdir)/src/InternalUtils.vala \
	$(top_srcdir)/src/Main.vala \
	$(top_srcdir)/src/PluginManager.vala \
	$(top_srcdir)/src/ScreenSaver.vala \
	$(top_srcdir)/src/Settings.vala \
	$(top_srcdir)/src/ShadowEffect.vala \
	$(top_srcdir)/src/TextShadowEffect.vala \
	$(top_srcdir)/src/WindowListener.vala \
	$(top_srcdir)/src/WindowManager.vala \
	$(top_srcdir)/src/WorkspaceManager.vala \
	$(top_srcdir)/src/Background/Animation.vala \
	$(top_srcdir)/src/Background/Background.vala \
	$(top_srcdir)/src/Background/BackgroundCache.vala \
	$(top_srcdir)/src/Background/BackgroundContainer.vala \
	$(top_srcdir)/src/Background/BackgroundManager.vala \
	$(top_srcdir)/src/Background/BackgroundSource.vala \
	$(top_srcdir)/src/Background/SystemBackground.vala \
	$(top_srcdir)/src/Widgets/IconGroup.vala \
	$(top_srcdir)/src/Widgets/IconGroupContainer.vala \
	$(top_srcdir)/src/Widgets/MonitorClone.vala \
	$(top_srcdir)/src/Widgets/MultitaskingView.vala \
	$(top_srcdir)/src/Widgets/SafeWindowClone.vala \
	$(top_srcdir)/src/Widgets/WindowClone.vala \
	$(top_srcdir)/src/Widgets/WindowCloneContainer.vala \
	$(top_srcdir)/src/Widgets/WindowIconActor.vala \
	$(top_srcdir)/src/Widgets/WindowMenu.vala \
	$(top_srcdir)/src/Widgets/WindowOverview.vala \
	$(top_srcdir)/src/Widgets/WindowSwitcher.vala \
	$(top_srcdir)/src/Widgets/WorkspaceClone.vala \
	$(top_srcdir)/src/Widgets/WorkspaceInsertThumb.vala \
	$(NULL)

valadoc_flags_gala = \
	--force \
	--verbose \
	--package-name $(PACKAGE_NAME) \
	--package-version $(PACKAGE_VERSION) \
	$(GALA_DOCS_VALAFLAGS) \
	--driver "`$(VALAC) --version`" \
	--pkg config \
	--pkg cogl-fixes \
	--vapidir=$(top_builddir)/lib \
	--vapidir=$(top_srcdir)/vapi \
	$(NULL)

if HAVE_VALADOC

html: $(libgala_doc_files) $(gala_doc_files) Makefile
	$(AM_V_GEN)$(VALADOC) \
		-o gala/ \
		--doclet=html \
		--internal \
		$(valadoc_flags_gala) \
		$(filter %.vala,$^)

libhtml: $(libgala_doc_files) Makefile
	$(AM_V_GEN)$(VALADOC) \
		-o libgala/ \
		--doclet=html \
		$(valadoc_flags_gala) \
		$(filter %.vala,$^)

endif

distclean-local: distclean-docs
distclean-docs:
	rm -rf gala libgala

