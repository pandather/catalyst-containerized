#!/bin/bash
mkdir -p /var/tmp/catalyst/builds/default

emerge-webrsync
emerge --oneshot --usepkg --buildpkg portage
emerge --usepkg --buildpkg dev-util/catalyst net-dns/bind-tools dev-vcs/git app-arch/pixz

libtool --finish /usr/lib64

if [[ ! -f /var/tmp/catalyst/snapshots/gentoo-latest.tar.bz2 ]];
then
    catalyst -s latest
fi

catalyst -f /root/toExec.spec
