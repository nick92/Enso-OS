# Panther Launcher

A tweaked version of a fork of Slingshot Launcher. Built in Xfce Panel Plugin with added functionality such as being able to 'Star' items for easier future use

## Installing and Running 

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
