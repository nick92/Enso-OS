# Panther Launcher

A fork of a fork originally 'Slingshot Launcher' by the elementary team

Changed to work with Xfce Panel with added functionality such as being able to 'Save' items

![panther](https://i.imgur.com/pIFgCJh.png)

## Installing and Running 

### Dependencies 

	libgnome-menu-3-dev 
	libxfce4panel-2.0-dev 
	libplank-dev
	libxfce4util-dev
	libxfconf-0-dev

### Build and install 

Just type from a command line:

	mkdir build
	cd build
	cmake .. -DCMAKE_INSTALL_PREFIX=/usr
	make
	sudo make install
	./src/panther_launcher

## Changing the location of the launcher's window

It is possible to move the window to the bottom part of the screen. To do so,
just use *dconf* to set *org.rastersoft.panther.show-at-top* to *false*.

## Origianl creator

Created by Raster Software Vigo (rastersoft) 
http://www.rastersoft.com 
https://github.com/rastersoft/slingshot_gnome 

Forked for Xfce and Enso OS
