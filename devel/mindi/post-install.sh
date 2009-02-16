#!/bin/bash
#
# $Id$
#

if [ ! -f "mindi" ] ; then
    echo "Please 'cd' to the directory you have just untarred." >> /dev/stderr
    exit 1
fi

if [ "_$PREFIX" != "_" ]; then
	local=${HEAD}$PREFIX
	sublocal=$PREFIX
	if [ "_$CONFDIR" != "_" ]; then
		conf=${HEAD}$CONFDIR/PBPROJ
		subconf=$CONFDIR/PBPROJ
	else
		echo "CONFDIR should be defined if PREFIX is defined"
		exit -1
	fi
else
	local=/usr/local
	sublocal=$local
	if [ -f /usr/bin/mindi ]; then
		echo "WARNING: /usr/bin/mindi exists. You should probably remove the mindi package !"
	fi
	conf=$local/etc/PBPROJ
	subconf=$conf
fi

if [ _"$CACHEDIR" = _"" ]; then
	CACHEDIR=$local/var/cache/mindi
else
	CACHEDIR=${HEAD}$CACHEDIR
fi
locallib=$local/share/lib
sublocallib="$locallib/PBPROJ"


if uname -a | grep Knoppix > /dev/null || [ -e "/ramdisk/usr" ] ; then
    local=/ramdisk/usr
	sublocal=$local
	conf=/ramdisk/etc
	subconf=$conf
    export PATH=/ramdisk/usr/sbin:/ramdisk/usr/bin:/$PATH
fi

MINDIVER=PBVER
MINDIREV=PBREV
ARCH=`/bin/uname -m`
echo "mindi ${MINDIVER}-r${MINDIREV} will be installed under $local"

echo "Creating target directories ..."
install -m 755 -d $conf $sublocallib $CACHEDIR

echo "Copying files ..."
cp -af rootfs $sublocallib/mindi
chmod 755 $sublocallib/mindi/rootfs/sbin/*
install -m 644 msg-txt dev.tgz $sublocallib/mindi
install -m 644 deplist.txt udev.files proliant.files $conf

# Substitute variables for mindi
sed -i -e "s~^MINDI_PREFIX=XXX~MINDI_PREFIX=$sublocal~" -e "s~^MINDI_CONF=YYY~MINDI_CONF=$subconf~" -e "s~^MINDI_LIB=LLL~MINDI_LIB=$sublocallib~" $local/bin/mindi
sed -i -e "s~= "YYY"~= "$subconf"~" $local/bin/mindi-bkphw
install -m 755 parted2fdisk.pl $local/sbin

# Managing parted2fdisk
if [ "$ARCH" = "ia64" ] ; then
	(cd $local/sbin && ln -sf parted2fdisk.pl parted2fdisk)
	install -s -m 755 $local/sbin/parted2fdisk.pl $locallib/mindi/rootfs/sbin/parted2fdisk
	# Try to avoid the need ot additional perl modules at the moment
	perl -pi -e 's/use strict;//' $locallib/mindi/rootfs/sbin/parted2fdisk
else
	# FHS requires fdisk under /sbin
	(cd $local/sbin && ln -sf /sbin/fdisk parted2fdisk)
	echo "Symlinking fdisk to parted2fdisk"
	( cd $locallib/mindi/rootfs/sbin && ln -sf fdisk parted2fdisk)
fi

if [ "$PKGBUILDMINDI" != "true" ]; then
	chown -R root:root $sublocallib/mindi $conf
	chown root:root $local/sbin/parted2fdisk.pl 
	if [ "$ARCH" = "ia64" ] ; then
		chown root:root $local/sbin/parted2fdisk
	fi
fi

exit 0
