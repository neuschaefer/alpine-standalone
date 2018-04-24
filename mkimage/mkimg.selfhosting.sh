# SPDX-License-Identifier: MIT
# Copyright (C) 2018 Jonathan Neuschäfer
#
# This file provides a profile for mkimage.sh; It is based on
# aports/scripts/mkimg.minirootfs.sh.

section_selfhosting() {
	return 0
}

create_image_rootfs() {
	local _script=$(readlink -f "$scriptdir/genrootfs.sh")
	local output_file="$(readlink -f ${OUTDIR:-.})/$output_filename"

	(cd "$OUTDIR"; fakeroot "$_script" -k "$APKROOT"/etc/apk/keys \
		-r "$APKROOT"/etc/apk/repositories \
		-o "$output_file" \
		-a $ARCH \
		$rootfs_apks)
}

profile_selfhosting() {
	title="Self-hosting"
	desc="Self-hosting, source based Alpine Linux"
	image_ext=tar.gz
	output_format=rootfs
	arch="$ARCH" # hehehe... :)
	rootfs_apks="busybox alpine-baselayout alpine-keys apk-tools
		     libc-utils build-base abuild alpine-conf openrc
		     cryptsetup lvm2 openssh-server"
}
