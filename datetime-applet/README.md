# XfcePanelPlug Date &amp; Time 
A fork of elementary's datetime indicator for Xfce Panel

## Building and Installation

You'll need the following dependencies:

* cmake
* gobject-introspection
* libecal1.2-dev
* libedataserver1.2-dev
* libical-dev
* libgranite-dev
* valac >= 0.40.3

It's recommended to create a clean build environment

    mkdir build
    cd build/

Run `cmake` to configure the build environment and then `make` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make

To install, use `make install`

    sudo make install
