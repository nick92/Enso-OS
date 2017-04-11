pkgname=panther_launcher
pkgver=1.12.0
pkgrel=1
pkgdesc="A fork from Slingshot Launcher. Its main change is that it doesn't
depend on Gala, Granite or other libraries not available in regular
linux distros. It also has been ported to Autovala, allowing an
easier build. Finally, it also has an applet for Gnome Flashback and
an extension for Gnome Shell, allowing to use it from these desktops.
"
arch=('i686' 'x86_64')
depends=( 'atk' 'glib2' 'cairo' 'gtk3' 'pango' 'gdk-pixbuf2' 'libgee' 'json-glib' 'gnome-menus' 'libsoup' 'libx11' 'glibc' 'gnome-icon-theme' )
makedepends=( 'vala' 'glibc' 'atk' 'cairo' 'gtk3' 'gdk-pixbuf2' 'libgee' 'glib2' 'json-glib' 'gnome-menus' 'libsoup' 'pango' 'libx11' 'cmake' 'gettext' 'pkg-config' 'gcc' 'make' 'intltool' 'gnome-panel' 'mate-panel-gtk3' )
build() {
	rm -rf ${startdir}/install
	mkdir ${startdir}/install
	cd ${startdir}/install
	cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=/usr/lib
	make -j1
}

package() {
	cd ${startdir}/install
	make DESTDIR="$pkgdir/" install
}
