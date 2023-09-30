# %PROJECT_NAME%

<!-- Insert project description here -->

## Building

### Dependencies

- [GNU Make](https://www.gnu.org/software/make/) (build-time);
- [GCC](https://www.gnu.org/software/gcc/) (build-time).

Our focus is in supporting GCC + Linux, though other compilers / \*NIX systems may work, though
not officially supported.

### Building

This project can be built with:

```console
$ make
```

Build artifacts can be removed with:

```console
$ make clean
```

## Installation

After [building](#building), the program can be installed by running:

```console
$ make install
```

`$PREFIX` can be overridden, to install the program in another location:

```console
# PREFIX=/usr make install
```

The program can also be uninstalled. Just make sure you use the same `$PREFIX` you used for
installation:

```console
$ make uninstall
```

## Developers

%UNI_NOTICE%
All contributors must read the [DEVELOPERS.md](DEVELOPERS.md) guide.
