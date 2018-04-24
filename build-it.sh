#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2018 Jonathan Neuschäfer

set -e
umask 0022

# Parse command line options
while getopts "A:a:h" opt; do
	case $opt in
	A) APORTS="$OPTARG";;
	a) ARCH="$OPTARG";;
	h) cat <<-EOF
	Usage: $0 [ -A path/to/aports ] [ -a architecture ]
	       $0 -h
	EOF
	exit 0;;
	esac
done
shift $(( $OPTIND - 1))

if [ -z "$APORTS" ]; then
	echo "Please specify the root of your aports clone, using -A APORTS"
	exit 1
fi

[ -z "$ARCH" ] && ARCH=ppc
APORTS="$(realpath "$APORTS")"
REPO="$(realpath ~/packages/main)"
mkdir -p images

if [ "$(. /usr/share/abuild/functions.sh;
	arch_to_hostspec "$ARCH")" = unknown ]; then
	echo "Unsupported architecture! Please add $ARCH to /usr/share/abuild/functions.sh."
	exit 1
fi


banner() {
	printf "\e[1;37m*** $* ***\e[0m\n"
}


banner "Bootstrapping Alpine for $ARCH"
# Unfortunately, bootstrap.sh tries to build some packages which don't build
# on ppc. The easiest way to deal with this is to ignore any errors.
"$APORTS/scripts/bootstrap.sh" "$ARCH" || true


APORTS_VERSION=$(cd "$APORTS" && git describe)
APORTS_TARBALL="$(pwd)/images/aports-$APORTS_VERSION.tar.gz"
banner "Packing aports $APORTS_VERSION"
[ -f "$APORTS_TARBALL" ] || \
(cd "$APORTS" && \
	git archive "$APORTS_VERSION" --prefix=aports/ -o "$APORTS_TARBALL" )


#banner "Packing the package cache"
#APKCACHE_TARBALL="images/apk-cache-$ARCH.tar"
#[ -f "$APKCACHE_TARBALL" ] || \
#tar -c -C "$REPO/.." "main/$ARCH" --owner=root:0 --group=root:0 \
#	> "$APKCACHE_TARBALL"


banner "Generating the rootfs"
# enable mkimage.sh to find our profile
export HOME="$(pwd)"

"$APORTS/scripts/mkimage.sh" --outdir images --arch "$ARCH" --hostkeys \
	--repository "$REPO" --profile selfhosting


banner "Generating checksums"
(
	cd images
	sha256sum *.tar* > SHA256SUMS
	sha512sum *.tar* > SHA512SUMS
)


banner "DONE"
ls -lh images/
