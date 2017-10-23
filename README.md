# makedocker

This is just a simple shell script to aid the generation of Docker images for Python-based images.

## Building/Installing

### Build

     $ make

### Install

     # make install

You can mess around with the PREFIX, BINDIR and DATADIR environment variables to your liking here.
By default, PREFIX is `/usr/local`, BINDIR is `/bin`, and DATADIR is `/share`. Note that these
variables *must* be consistent across the build and install stages, as there are substitutions
going on in the build stage which are based on the values of these variables.

## License

makedocker is licensed under the GNU GPLv3
