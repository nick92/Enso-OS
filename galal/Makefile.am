include $(top_srcdir)/Makefile.common

ACLOCAL_AMFLAGS = --install -I m4 ${ACLOCAL_FLAGS}

SUBDIRS = \
	data \
	lib \
	plugins \
	src \
	docs \
	po \
	vapi \
	$(NULL)

EXTRA_DIST = \
	.version \
	build-aux/bzr-version-gen \
	$(NULL)

BUILT_SOURCES = \
	$(top_srcdir)/.version \
	$(NULL)

$(top_srcdir)/.version:
	echo $(VERSION) > $@-t && mv $@-t $@

dist-hook:
	echo $(VERSION) > $(distdir)/.tarball-version

distclean-local:
	if test "x$(srcdir)" = "x."; then :; else \
		rm -f ChangeLog; \
	fi

ChangeLog:
	@echo Creating $@
	@if test -d "$(srcdir)/.bzr"; then \
		(bzr log --gnu -n1) | fmt --split-only --width=80 > $@.tmp \
		&& mv -f $@.tmp $@ \
		|| ($(RM) $@.tmp; \
			echo Failed to generate ChangeLog, your ChangeLog may be outdated >&2; \
			(test -f $@ || echo git-log is required to generate this file >> $@)); \
	else \
		test -f $@ || \
		(echo A git checkout and git-log is required to generate ChangeLog >&2 && \
		echo A git checkout and git-log is required to generate this file >> $@); \
	fi

.PHONY: ChangeLog

