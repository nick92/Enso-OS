## Plank

Plank is meant to be the simplest dock on the planet. The goal is to provide
just what a dock needs and absolutely nothing more. It is, however, a library
which can be extended to create other dock programs with more advanced features.

(Codenames for releases are currently based on characters of "Ed, Edd n Eddy".)


## Reporting Bugs

You can report bugs here: https://bugs.launchpad.net/plank
Please try and avoid making duplicate bugs - search for existing bugs before
reporting a new bug!
You also might want to jump on our IRC channel (see below)


## Where Can I Get Help?

IRC: #plank on FreeNode - irc://irc.freenode.net/#plank
Common problems and solutions
https://answers.launchpad.net/plank


## How Can I Get Involved?

Visit the Launchpad page: https://launchpad.net/plank
Help translate: https://translations.launchpad.net/plank
Answer questions: https://answers.launchpad.net/plank


## Are there online API documentations?

http://people.ubuntu.com/~ricotz/docs/vala-doc/plank/index.htm


## Need more information about Vala?

https://wiki.gnome.org/Projects/Vala
https://wiki.gnome.org/Projects/Vala/Manual


Refer to the HACKING file for further instructions.

## Building, Testing, and Installation

You'll need the following dependencies:
* meson
* libgtk-3-dev
* libgee-0.8-dev
* libbamf3-dev
* libcairo2-dev
* libwnck-3-dev
* valac (>= 0.28.0)

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `plank`

    sudo ninja install
    plank