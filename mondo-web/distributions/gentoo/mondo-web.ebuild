# Copyright 1999-2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# $Id$

inherit libtool

DESCRIPTION="The premier GPL disaster recovery solution."
HOMEPAGE="http://www.mondorescue.org"
SRC_URI="ftp://ftp.mondorescue.org/src/${PN/-rescue/}-${PV}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* ~x86"
IUSE=""

DEPEND="virtual/libc
	>=sys-libs/slang-1.4.1
	>=dev-libs/newt-0.50"
RDEPEND="app-arch/afio
	sys-block/buffer
	sys-devel/binutils
	>=app-arch/bzip2-0.9
	app-cdr/cdrtools
	>=sys-apps/mindi-1.0.7
	>=dev-libs/newt-0.50
	>=sys-libs/slang-1.4.1
	>=sys-boot/syslinux-1.52"

S=${WORKDIR}/${PN/-rescue/}-${PV}

src_unpack() {
	unpack ${A}
	cd ${S}
	chmod 750 configure
}

src_compile() {
	elibtoolize
	econf || die "Configuration failed"
	emake || die "Make failed"
	#make VERSION=VVV CFLAGS="-D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_REENTRANT"
}

src_install() {
	#make install DESTDIR=${D} || die "make install failed"
	einstall || die "Install failed"
	exeinto /usr/share/mondo
	doexe mondo/autorun
}

pkg_postinst() {
	einfo "${P} was successfully installed."
	einfo "Please read the associated docs for help."
	einfo "Or visit the website @ ${HOMEPAGE}"
	echo
	ewarn "This package is still in unstable."
	ewarn "Please report bugs to http://bugs.gentoo.org/"
	ewarn "However, please do an advanced query to search for bugs"
	ewarn "before reporting. This will keep down on duplicates."
	echo
	einfo "Prior to running mondo, ensure /boot is mounted."
	ewarn "Grub users need to have a symlink like this:"
	ewarn "ln -s /boot/grub/menu.lst /etc/grub.conf"
	einfo "Unless you want to have mondo backup your distfiles,"
	einfo "append \"-E ${DISTDIR}\" to your mondoarchive command."
	echo
}
