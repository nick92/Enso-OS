## Greeter

A fork of pantheon greeter

## Building and Installation

You'll need the following dependencies:

* cmake
* libclutter-gtk-2.0-dev
* libgdk-pixbuf2.0-dev
* libgee-0.8-dev
* libgtk-3-dev
* liblightdm-gobject-1-dev
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