# Gala Window Manager Alternative Window Switcher

This is a modified version of the original [Gala Alternate Alt-Tab Plugin](https://github.com/tom95/gala-alternate-alt-tab) by [Tom Beckmann](https://github.com/tom95).

Instead of showing icons, this version shows a window overview like preview of the current workspace.

![screenshot](Screenshot.png)

Please be aware of that it's Currently a prototype and won't work properly in all cases.

## Installing & building

```bash
$ mkdir build && cd build/
$ cmake .. -DCMAKE_INSTALL_PREFIX=/usr
$ make
$ make install
```
