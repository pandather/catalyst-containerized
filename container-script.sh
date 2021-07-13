#!/bin/bash
mkdir -p /var/tmp/catalyst/builds/default

emerge-webrsync
emerge --oneshot --usepkg --buildpkg portage
emerge --usepkg --buildpkg dev-util/catalyst net-dns/bind-tools dev-vcs/git app-arch/pixz

libtool --finish /usr/lib64

if [[ -f /var/tmp/catalyst/snapshots/gentoo-$(date +%Y-%m-%d).tar.bz2 ]];
then
    catalyst -s $(date +%Y-%m-%d)
fi

catalyst -f /root/toExec.spec
