## Greeter

A fork of pantheon greeter that positions elements in a central and vertigal manner and adds a blur effect to the background

blur effeet can be enabled by amending greeter.conf in /etc/lightdm and setting blur=true 

![greeter](https://i.imgur.com/LdOc6h1.png)

## Building and Installation

You'll need the following dependencies(Ubuntu):

* cmake
* libclutter-gtk-1.0-dev
* libgdk-pixbuf2.0-dev
* libgee-0.8-dev
* libgtk-3-dev
* liblightdm-gobject-1-dev
* libx11-dev
* valac

You'll need the following dependencies(Debian):

* cmake
* libclutter-gtk-1.0-dev
* libgdk-pixbuf2.0-dev
* libgee-0.8-dev
* libgtk-3-dev
* liblightdm-gobject-dev
* lightdm-vala
* libx11-dev
* valac

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make
    
To install, use `make install`

    sudo make install

## Testing & Debugging

Run LightDM in test mode with Xephyr:

    lightdm --test-mode --debug

You can then find the debug log in `~/.cache/lightdm/log`

Also by running the local executable

    ./pantheon-greeter 

from you build folder

## Changelog

1.0.7

	* brightness setting added to config file - set to anything less than 1 to dim login
 
1.0.6
	
	* add blur effect to background (can be enabled through config file with blur=true)
	* Positional fixes for clock
	* change launcher name from pantheon-greeter to greeter

1.0.5

	* update shutdown icon

1.0.4

	* change position of time lable 
	* set up time lable default width and height
	* change location of power button to top right	

1.0.3

	* added description

1.0.2

	* remove install file

1.0.1

	* change libclutter gtk deps from 2 to 1

1.0.0

	* Initial release
