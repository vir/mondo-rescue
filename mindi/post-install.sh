#!/bin/bash
#
# $Id$
#

if [ "_$PREFIX" != "_" ]; then
	local=${HEAD}$PREFIX
	sublocal=$PREFIX
	if [ "_$CONFDIR" != "_" ]; then
		conf=${HEAD}$CONFDIR/PBPKG
		subconf=$CONFDIR/PBPKG
	else
		echo "CONFDIR should be defined if PREFIX is defined"
		exit -1
	fi
else
	local=/usr/local
	sublocal=$local
	conf=$local/etc/PBPKG
	subconf=$conf
fi

if [ _"$CACHEDIR" = _"" ]; then
	CACHEDIR=$local/var/cache/PBPKG
else
	CACHEDIR=${HEAD}$CACHEDIR
fi
sublocalshare="$local/share/PBPKG"
sublocallib="$local/lib/PBPKG"

MINDIVER=PBVER
MINDIREV=PBREV
ARCH=`/bin/uname -m`
echo "mindi ${MINDIVER}-r${MINDIREV} will be installed under $local"

echo "Creating target directories ..."
install -m 755 -d $conf $sublocallib $sublocalshare $CACHEDIR

#echo "Copying files ..."
#cp -af rootfs $sublocallib/mindi
#chmod 755 $sublocallib/mindi/rootfs/sbin/*
#install -m 644 msg-txt dev.tgz $sublocallib/mindi
#install -m 644 deplist.txt udev.files proliant.files $conf

# Substitute variables for mindi
sed -i -e "s~^MINDI_PREFIX=XXX~MINDI_PREFIX=$sublocal~" -e "s~^MINDI_CONF=YYY~MINDI_CONF=$subconf~" -e "s~^MINDI_LIB=LLL~MINDI_LIB=$sublocallib~" $local/bin/mindi
#sed -i -e "s~= "YYY"~= "$subconf"~" $local/bin/mindi-bkphw

if [ "$PKGBUILDMINDI" != "true" ]; then
	chown -R root:root $sublocallib/mindi $conf
fi

exit 0
