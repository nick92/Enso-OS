SUBDIRS = \
	icons \
	$(NULL)

stylesdir = $(pkgdatadir)
styles_DATA = gala.css texture.png close.svg

applicationsdir = $(datadir)/applications
applications_DATA = gala.desktop gala-wayland.desktop gala-other.desktop gala-multitaskingview.desktop

gsettings_SCHEMAS = org.pantheon.desktop.gala.gschema.xml

%.gschema.xml: %.gschema.xml.in Makefile
	$(AM_V_GEN) sed -e 's|@GETTEXT_PACKAGE[@]|$(GETTEXT_PACKAGE)|g' \
	$< > $@ || rm $@

@GSETTINGS_RULES@

gschemas.compiled: Makefile $(gsettings_SCHEMAS:.xml=.valid)
	$(AM_V_GEN) $(GLIB_COMPILE_SCHEMAS) --targetdir=$(builddir) $(builddir)

all-local: gschemas.compiled

%.desktop: %.desktop.in
	$(AM_V_GEN)$(MSGFMT) --desktop --keyword= --keyword=Name \
		--keyword=GenericName --keyword=Comment --keyword=Keywords \
		--template $< -d $(top_srcdir)/po -o $@

%.appdata.xml: %.appdata.xml.in
	$(AM_V_GEN)$(MSGFMT) --xml --template $< -d $(top_srcdir)/po -o $@

EXTRA_DIST = \
	gala.css \
	gala.desktop \
	gala-wayland.desktop \
	gala-other.desktop.in \
	gala-multitaskingview.desktop.in \
	texture.png \
	close.svg \
	org.pantheon.desktop.gala.gschema.xml.in \
	$(NULL)

CLEANFILES = \
	gala-other.desktop \
	gala-multitaskingview.desktop \
	gschemas.compiled \
	org.pantheon.desktop.gala.gschema.xml \
	$(NULL)

