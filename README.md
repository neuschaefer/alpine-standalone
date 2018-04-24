# Alpine Linux as a stand-alone source-based distro

This repository contains a script to build Alpine Linux for architectures
where no binary packages are offered (such as ppc and mips).


## General Usage

1. Have a machine (or chroot, or container) where [abuild], Alpine Linux's
   package build tool, is installed.
2. Clone [aports], Alpine Linux's repository of package definitions
3. Set up your user account for use with abuild
4. Run `./build-it.sh -A /path/to/aports/` to bootstrap Alpine Linux. You can
   specify your target architecture with `-a ARCH`; ppc is assumed by default.
   [build-it.sh] will create a few files in the images/ directory.
5. Install a bootloader and kernel on your target machine, and unpack the
   rootfs tarball (`alpine-selfhosting-*-*.tar.gz`). Copy the aports tarball
   to a storage medium that can be accessed from the target machine.
6. Boot the target machine, using the unpacked rootfs either directly or with
   `chroot`. Make sure you have an internet connection; otherwise, abuild
   won't be able to download any source code.
   (Or pre-populate `/var/cache/distfiles/` with all the packages required to
   get an internet connection.)
7. Create a user account and set it up for use with abuild.
   Adjust `/etc/apk/repositories` to include `/home/$user/packages/main`.
8. Adjust `/etc/abuild.conf` or `/home/$user/.abuild/abuild.conf` to your
   machine (especially `JOBS` and `MAKEFLAGS` are worth configuring).
9. Start building the rest of the system with `abuild`. You may encounter a
   number of problems, some of which are documented below. You will have to
   build a lot of packages before `git` is available. That's why `build-it.sh`
   packs the aports tree as a tarball.

[abuild]: https://git.alpinelinux.org/cgit/abuild/
[aports]: https://git.alpinelinux.org/cgit/aports/


## Known bootstrapping problems

### Circular dependencies

- gzip `checkdepends` on coreutils, which `makedepends` on attr-dev, which
  `makedepends` on gzip. Build gzip with `ABUILD_BOOTSTRAP=1` to disable tests
  and break this cycle.
- bison `checkdepends` on flex, which `makedepends` on bison. Build bison with
  `ABUILD_BOOTSTRAP=1` or `BOOTSTRAP=1` to break this cycle.

### Test failures

I recommend trying to build every package with tests enabled, and only
bypassing the tests when necessary.

- XZ's test suite doesn't find its library (`liblzma.so`) when it isn't
  installed system-wide. A patch is available.
- M4 fails its test suite when running in a chroot with `qemu-ppc`, for unknown
  reasons.
- Python3 fails multiple tests of its test suite under `qemu-ppc`.
- libnl fails its test suite with
  `genl_connect: socket(AF_NETLINK, ...) failed (errno = Operation not permitted)`
  when running under `qemu-ppc`.
