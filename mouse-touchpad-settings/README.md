# Switchboard Mouse & Touchpad Plug
[![l10n](https://l10n.elementary.io/widgets/switchboard/switchboard-plug-mouse-touchpad/svg-badge.svg)](https://l10n.elementary.io/projects/switchboard/switchboard-plug-mouse-touchpad)

![screenshot](data/screenshot-general.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* libgranite-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install
