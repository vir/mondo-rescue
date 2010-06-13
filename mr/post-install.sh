#!/bin/bash
#
# $Id$
#

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
	conf=$local/etc/PBPROJ
	subconf=$conf
fi

if [ _"$CACHEDIR" = _"" ]; then
	CACHEDIR=$local/var/cache/PBPROJ
else
	CACHEDIR=${HEAD}$CACHEDIR
fi
sublocalshare="$local/share/PBPROJ"
sublocallib="$local/lib/PBPROJ"

MRVER=PBVER
MRREV=PBREV
ARCH=`/bin/uname -m`
echo "PBPROJ modules ${MRVER}-r${MRREV} will be installed under $local"

echo "Creating target directories ..."
install -m 755 -d $conf $sublocallib $sublocalshare $CACHEDIR

echo "Copying files ..."
cp etc/PBPROJ.conf $conf
cat > $HEAD$PERLDIR/MondoRescue/DynConf.pm << EOF
#!/usr/bin/perl -w
#
# Declare variables for the MondoRescue project
# This module has been generated at installation time
# Do not modify without good reasons.
#
package MondoRescue::DynConf;

use strict;

# Inherit from the "Exporter" module which handles exporting functions.
 
use Exporter;
 
# Export, by default, all the functions into the namespace of
# any code which uses this module.
our @ISA = qw(Exporter);
our @EXPORT = qw(mr_dynconf_init);

# Returns in order
# the CONFDIR
# the LOCALDIR
sub mr_dynconf_init {

return("$subconf","$sublocal","PBPROJ");
}
1;
EOF

exit 0
