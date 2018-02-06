# User Accounts Settings 

A fork of elementary user accounts plug to run as stand alone application

## Building and Installation

You'll need the following dependencies:

* cmake
* libaccountsservice-dev
* libgirepository1.0-dev 
* libgnome-desktop-3-dev
* libgranite-dev
* libpolkit-gobject-1-dev
* libpwquality-dev
* libswitchboard-2.0-dev
* valac

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make
    
To install, use `make install`, then execute with `switchboard`

    sudo make install
    switchboard

