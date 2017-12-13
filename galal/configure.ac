# If not 1, append revision to the version number and enable other development stuff
m4_define([gala_released], [0])

m4_define([gala_major_version], [0])
m4_define([gala_minor_version], [3])
m4_define([gala_micro_version], [0])
m4_define([gala_nano_version], [0])

# If library source has changed since last release, increment revision
# If interfaces have been removed or changed since last release,
#  increment current and set revision to 0
# If interfaces have been added since last release, increment age
# If interfaces have been removed since last release, set age to 0
m4_define([gala_lt_current], [0])
m4_define([gala_lt_revision], [0])
m4_define([gala_lt_age], [0])

# Display the nano_version only if it's not '0'
m4_define([gala_base_version],
          gala_major_version.gala_minor_version.gala_micro_version)
m4_define([gala_full_version],
          [m4_if(gala_nano_version, [0],
                 gala_base_version, gala_base_version.gala_nano_version)])

# Extend version with bzr revision for non-release builds
m4_define([gala_version], m4_if(gala_released, [1],
          [gala_full_version], [m4_esyscmd([build-aux/git-version-gen --prefix "" --fallback gala_full_version $srcdir/.tarball-version])]))
m4_define([gala_major_minor_version], gala_major_version.gala_minor_version)
m4_define([gala_module_version], gala_lt_current)

AC_INIT([gala], gala_version,
        [https://bugs.launchpad.net/gala], [gala],
        [https://launchpad.net/gala])
AC_DEFINE(RELEASE_NAME, "Window Manager.", Codename of this release)
AC_DEFINE(VERSION_INFO, m4_if(gala_released, [1], "Release", "Development"), Version info for package)

m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PREREQ([2.65])

AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AC_CONFIG_SRCDIR([configure.ac])
AM_INIT_AUTOMAKE([1.11 foreign tar-ustar dist-xz no-dist-gzip -Wno-portability subdir-objects])

AM_MAINTAINER_MODE([enable])

AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_INSTALL

GETTEXT_PACKAGE=AC_PACKAGE_NAME
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, ["$GETTEXT_PACKAGE"], [Define the gettext package to be used])

AM_GNU_GETTEXT_VERSION([0.19.6])
AM_GNU_GETTEXT([external])

LT_PREREQ([2.2.6])
LT_INIT([disable-static])
PKG_PROG_PKG_CONFIG([0.21])

LT_LIB_M

GLIB_GSETTINGS

AC_SUBST([CFLAGS])
AC_SUBST([CPPFLAGS])
AC_SUBST([LDFLAGS])

LT_CURRENT=gala_lt_current
LT_REVISION=gala_lt_revision
LT_AGE=gala_lt_age
AC_SUBST([LT_CURRENT])
AC_SUBST([LT_REVISION])
AC_SUBST([LT_AGE])

GALA_MAJOR_MINOR_VERSION=gala_major_minor_version
AC_SUBST([GALA_MAJOR_MINOR_VERSION])

API_VERSION=0.2
AC_SUBST([API_VERSION])


# -----------------------------------------------------------
# Vala
# -----------------------------------------------------------
VALA_MIN_VERSION=0.28.0

AM_PROG_VALAC([$VALA_MIN_VERSION])
if test "x$VALAC" = "x"; then
    AC_MSG_ERROR([Vala requested but valac >= $VALA_MIN_VERSION is not installed])
fi

AC_PATH_PROG([VAPIGEN], [vapigen], [])
if test "x$VAPIGEN" = "x"; then
    AC_MSG_ERROR([Vala must be built with --enable-vapigen])
fi

# -----------------------------------------------------------
# Dependencies
# -----------------------------------------------------------
GTK_MIN_VERSION=3.4.0
GLIB_MIN_VERSION=2.44.0
PLANK_MIN_VERSION=0.3.0
CLUTTER_MIN_VERSION=1.12.0
MUTTER_MIN_VERSION=3.14.4
MUTTER_API="3.14"

GALA_CORE_PKGS="gobject-2.0 >= $GLIB_MIN_VERSION \
                 glib-2.0 >= $GLIB_MIN_VERSION \
                 gio-2.0 >= $GLIB_MIN_VERSION \
                 gio-unix-2.0 >= $GLIB_MIN_VERSION \
                 gmodule-2.0 \
                 gtk+-3.0 >= $GTK_MIN_VERSION \
                 gdk-x11-3.0 >= $GTK_MIN_VERSION \
                 libbamf3 \
                 granite \
                 gee-0.8 \
                 gnome-desktop-3.0 \
                 plank >= $PLANK_MIN_VERSION"

GALA_CORE_VALA_PKGS="--pkg gio-unix-2.0 \
                      --pkg gmodule-2.0 \
                      --pkg gtk+-3.0 \
                      --pkg gdk-x11-3.0 \
                      --pkg libbamf3 \
                      --pkg granite \
                      --pkg gee-0.8 \
                      --pkg gdesktopenums-3.0 \
                      --pkg gnome-desktop-3.0 \
                      --pkg xfixes-4.0 \
                      --pkg plank"

VALAFLAGS="--target-glib=2.44"
VALAFLAGS_CORE=""

MUTTER_PKGS="cogl-1.0 clutter-1.0 >= $CLUTTER_MIN_VERSION libmutter >= $MUTTER_MIN_VERSION"
MUTTER_VALA_PKGS="--pkg cogl-1.0 --pkg clutter-1.0 --pkg libmutter"
MUTTER_CFLAGS=""
MUTTER_LDFLAGS=""

# Plugins
PLUGIN_LDFLAGS="-module -avoid-version"
AC_SUBST([PLUGIN_LDFLAGS])

# -----------------------------------------------------------
# Optional Dependencies
# -----------------------------------------------------------

# 3.16
PKG_CHECK_MODULES(MUTTER316, [libmutter >= 3.15], [have_mutter316=yes], [have_mutter316=no])
if test "x$have_mutter316" = "xyes" ; then
    PKG_CHECK_MODULES(MUTTER316, [libmutter >= 3.16.4])
    VALAFLAGS="$VALAFLAGS --define HAS_MUTTER316"
    MUTTER_API="3.16"
fi

# 3.18
PKG_CHECK_MODULES(MUTTER318, [libmutter >= 3.17], [have_mutter318=yes], [have_mutter318=no])
if test "x$have_mutter318" = "xyes" ; then
    PKG_CHECK_MODULES(MUTTER318, [libmutter >= 3.18.4])
    VALAFLAGS="$VALAFLAGS --define HAS_MUTTER318"
    MUTTER_API="3.18"
fi

# 3.20
PKG_CHECK_MODULES(MUTTER320, [libmutter >= 3.19], [have_mutter320=yes], [have_mutter320=no])
if test "x$have_mutter320" = "xyes" ; then
    PKG_CHECK_MODULES(MUTTER320, [libmutter >= 3.20.3])
    VALAFLAGS="$VALAFLAGS --define HAS_MUTTER320"
    MUTTER_API="3.20"
fi

# 3.22
PKG_CHECK_MODULES(MUTTER322, [libmutter >= 3.21], [have_mutter322=yes], [have_mutter322=no])
if test "x$have_mutter322" = "xyes" ; then
    PKG_CHECK_MODULES(MUTTER322, [libmutter >= 3.22.0])
    VALAFLAGS="$VALAFLAGS --define HAS_MUTTER322"
    MUTTER_CFLAGS="-DCLUTTER_ENABLE_COMPOSITOR_API -DCLUTTER_ENABLE_EXPERIMENTAL_API -DCOGL_ENABLE_EXPERIMENTAL_API -DCOGL_ENABLE_EXPERIMENTAL_2_0_API"
    MUTTER_PKGS="mutter-cogl-1.0 mutter-cogl-pango-1.0 mutter-cogl-path-1.0 mutter-clutter-1.0 libmutter >= 3.22"
    MUTTER_VALA_PKGS="--pkg mutter-cogl-1.0 --pkg mutter-clutter-1.0 --pkg libmutter"
    MUTTER_API="3.22"
    MUTTER_LDFLAGS="-R`$PKG_CONFIG --variable=typelibdir libmutter`"
fi

# 3.24
PKG_CHECK_MODULES(MUTTER324, [libmutter-0 >= 3.23], [have_mutter324=yes], [have_mutter324=no])
if test "x$have_mutter324" = "xyes" ; then
    PKG_CHECK_MODULES(MUTTER324, [libmutter >= 3.23.90])
    VALAFLAGS="$VALAFLAGS --define HAS_MUTTER316 --define HAS_MUTTER318 --define HAS_MUTTER320 --define HAS_MUTTER322"
    VALAFLAGS="$VALAFLAGS --define HAS_MUTTER324"
    MUTTER_CFLAGS="-DCLUTTER_ENABLE_COMPOSITOR_API -DCLUTTER_ENABLE_EXPERIMENTAL_API -DCOGL_ENABLE_EXPERIMENTAL_API -DCOGL_ENABLE_EXPERIMENTAL_2_0_API"
    MUTTER_PKGS="mutter-cogl-0 mutter-cogl-pango-0 mutter-cogl-path-0 mutter-clutter-0 libmutter-0 >= 3.23.90"
    MUTTER_VALA_PKGS="--pkg mutter-cogl-0 --pkg mutter-clutter-0 --pkg libmutter-0"
    MUTTER_API="3.24"
    MUTTER_LDFLAGS="-R`$PKG_CONFIG --variable=typelibdir libmutter-0`"
fi

# Check for newer Plank
PLANK_PKGS="plank >= 0.10.9"
PKG_CHECK_MODULES(PLANK_0_11, $PLANK_PKGS, [enable_plank_0_11=yes], [enable_plank_0_11=no])
if test "x$enable_plank_0_11" = "xyes" ; then
    VALAFLAGS="$VALAFLAGS --define HAVE_PLANK_0_11"
fi

# Check for Gnome Settings Daemon 3.10
PKG_CHECK_MODULES(GSD310, [gnome-settings-daemon >= 3.9.5], [have_gsd310=yes], [have_gsd310=no])
if test "x$have_gsd310" = "xyes" ; then
    VALAFLAGS="$VALAFLAGS --define HAS_GSD310"
fi
PKG_CHECK_MODULES(GSD316, [gnome-settings-daemon >= 3.15.2], [have_gsd316=yes], [have_gsd316=no])
if test "x$have_gsd316" = "xyes" ; then
    VALAFLAGS="$VALAFLAGS --define HAS_GSD316"
fi

GALA_CORE_PKGS="$GALA_CORE_PKGS $MUTTER_PKGS"
GALA_CORE_VALA_PKGS="$GALA_CORE_VALA_PKGS $MUTTER_VALA_PKGS"
CFLAGS="$CFLAGS $MUTTER_CFLAGS"
LDFLAGS="$LDFLAGS $MUTTER_LDFLAGS"

PKG_CHECK_MODULES(GALA_CORE, $GALA_CORE_PKGS)
AC_SUBST([MUTTER_PKGS])
AC_SUBST([MUTTER_CFLAGS])

# -----------------------------------------------------------
# Dependencies for Notifications plugin
# -----------------------------------------------------------

NOTIFICATION_PLUGIN_PKGS="libcanberra \
                          libcanberra-gtk3"

NOTIFICATION_PLUGIN_VALA_PKGS="--pkg libcanberra \
                               --pkg libcanberra-gtk"

PKG_CHECK_MODULES(NOTIFICAION_PLUGIN, $NOTIFICATION_PLUGIN_PKGS)

AC_SUBST([NOTIFICATION_PLUGIN_VALA_PKGS])

# -----------------------------------------------------------
# Additional configure flags
# -----------------------------------------------------------

# Enable Vala debug-flag by default for non-release builds
AC_ARG_ENABLE([debug],
              AS_HELP_STRING([--disable-debug],[compile without debug code]),
              [enable_debug=$enableval], [m4_if(gala_released, [1], [enable_debug=no], [enable_debug=yes])])
if test "x$enable_debug" = "xyes" ; then
    VALAFLAGS_CORE="$VALAFLAGS_CORE -g"
fi

GALA_CORE_VALAFLAGS="$VALAFLAGS $VALAFLAGS_CORE $GALA_CORE_VALA_PKGS"
AC_SUBST(GALA_CORE_VALAFLAGS)
GALA_DOCS_VALAFLAGS="$VALAFLAGS $GALA_CORE_VALA_PKGS"
AC_SUBST(GALA_DOCS_VALAFLAGS)

# -----------------------------------------------------------
# Additional build flags
# -----------------------------------------------------------

# Use RUNPATH instead of RPATH if needed
CFLAGS="$CFLAGS -Wl,--enable-new-dtags"

# -----------------------------------------------------------
# Documentation
# -----------------------------------------------------------
VALADOC_MIN_VERSION=0.3.1

AC_ARG_ENABLE([docs],
              AS_HELP_STRING([--enable-docs],[Enable documentation generation]),
              [enable_docs=$enableval], [enable_docs=no])
AM_CONDITIONAL([ENABLE_DOCS], [test "x$enable_docs" = "xyes"])

have_valadoc=no
if test "x$enable_docs" = "xyes"; then
    # make sure the library is new enough and the program exists
    PKG_CHECK_MODULES([VALADOC], [valadoc-1.0 >= $VALADOC_MIN_VERSION])
    AC_PATH_PROG([VALADOC], [valadoc], [:])
    AS_IF([test "$VALADOC" != :], have_valadoc=yes)
fi
AM_CONDITIONAL([HAVE_VALADOC], [test "x$have_valadoc" = "xyes"])

if test "x$enable_docs" = "xyes" -a "x$have_valadoc" != "xyes"; then
    AC_MSG_ERROR([Doc building requested but valadoc not installed.])
fi

# -----------------------------------------------------------
# Final output
# -----------------------------------------------------------
AC_CONFIG_FILES([
Makefile
src/Makefile
lib/Makefile
lib/gala.pc
docs/Makefile
data/Makefile
data/icons/Makefile
vapi/Makefile
plugins/Makefile
plugins/maskcorners/Makefile
plugins/notify/Makefile
plugins/zoom/Makefile
po/Makefile.in
])

AC_OUTPUT

echo "
${PACKAGE} ${VERSION}

    Prefix......................:  ${prefix}
    Vala Compiler...............:  ${VALAC}
    Vala Flags..................:  ${VALAFLAGS}
    C Compiler Flags............:  ${CFLAGS}

    Using Mutter................:  ${MUTTER_API}

    Documentation...............:  ${have_valadoc}
"
