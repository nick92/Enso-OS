Name: panther_launcher
Version: 1.12.0
Release: 1
License: Unknown/not set
Summary: A fork from Slingshot Launcher. Its main change is that it doesn't depend on Gala, Granite or other libraries not available in regular linux distros. It also has been ported to Autovala, allowing an easier build. Finally, it also has an applet for Gnome Flashback and an extension for Gnome Shell, allowing to use it from these desktops.
AutoReqProv: no

BuildRequires: gcc
BuildRequires: gcc-c++
BuildRequires: vala
BuildRequires: glibc-headers
BuildRequires: atk-devel
BuildRequires: cairo-devel
BuildRequires: gtk3-devel
BuildRequires: gdk-pixbuf2-devel
BuildRequires: libgee-devel
BuildRequires: glib2-devel
BuildRequires: json-glib-devel
BuildRequires: gnome-menus-devel
BuildRequires: libsoup-devel
BuildRequires: pango-devel
BuildRequires: libX11-devel
BuildRequires: cmake
BuildRequires: gettext
BuildRequires: pkgconfig
BuildRequires: make
BuildRequires: intltool
BuildRequires: gnome-panel-devel
BuildRequires: mate-panel-devel

Requires: atk
Requires: glib2
Requires: cairo
Requires: gtk3
Requires: pango
Requires: gdk-pixbuf2
Requires: cairo-gobject
Requires: libgee
Requires: json-glib
Requires: gnome-menus
Requires: libsoup
Requires: libX11
Requires: glibc-devel
Requires: gnome-icon-theme

%description
A fork from Slingshot Launcher. Its main change is that it doesn't
depend on Gala, Granite or other libraries not available in regular
linux distros. It also has been ported to Autovala, allowing an
easier build. Finally, it also has an applet for Gnome Flashback and
an extension for Gnome Shell, allowing to use it from these desktops.
.

%files
*

%build
mkdir -p ${RPM_BUILD_DIR}
cd ${RPM_BUILD_DIR}; cmake -DCMAKE_INSTALL_PREFIX=/usr -DGSETTINGS_COMPILE=OFF -DICON_UPDATE=OFF ../..
make -C ${RPM_BUILD_DIR}

%install
make install -C ${RPM_BUILD_DIR} DESTDIR=%{buildroot}

%post
glib-compile-schemas /usr/share/glib-2.0/schemas

%postun
glib-compile-schemas /usr/share/glib-2.0/schemas

%clean
rm -rf %{buildroot}

