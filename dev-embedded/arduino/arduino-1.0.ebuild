# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-embedded/arduino/arduino-0017.ebuild,v 1.1 2009/10/17 18:15:07 nixphoeni Exp $

EAPI=3
inherit eutils

DESCRIPTION="Arduino is an open-source AVR electronics prototyping platform"
HOMEPAGE="http://arduino.cc/"
SRC_URI="x86?   ( http://arduino.googlecode.com/files/${P}-linux.tgz )
		 amd64? ( http://arduino.googlecode.com/files/${P}-linux64.tgz )"

LICENSE="GPL-2 LGPL-2 CCPL-Attribution-ShareAlike-3.0"
SLOT="0"
KEYWORDS="~x86 ~amd64"
RESTRICT="strip binchecks"
IUSE="+java"
RDEPEND="dev-embedded/avrdude 
	sys-devel/crossdev"
DEPEND="${RDEPEND} java? (
	virtual/jre
	dev-embedded/uisp
	dev-java/jikes
	dev-java/jna
	>=dev-java/rxtx-2.2_pre2 )"

pkg_setup() {
	[ ! -x /usr/bin/avr-g++ ] && ewarn "Missing avr-g++; See http://en.gentoo-wiki.com/wiki/Crossdev#AVR_Architecture for toolchain build instructions"
	einfo "Note that you need >=cross-avr/gcc-4.4.1, if you intend to use the new"
	einfo "Arduino Mega 2560."
}

pkg_postinst() {
	pkg_setup
}

src_prepare() {
	# avrdude has it's own ebuild
	rm -rf hardware/tools/avrdude*
	# -java don't build IDE
	if ! use java; then
		rm -rf lib
		rm -f arduino
	else
		# fix the provided arduino script to call out the right
		# libraries, remove resetting of $PATH, and fix its
		# reference to LD_LIBRARY_PATH (see bug #189249)
		epatch "${FILESDIR}"/arduino-script-${PV}.patch || die "epatch failed"
	fi
}

src_install() {
	mkdir -p "${D}/usr/share/${P}/" "${D}/usr/bin"
	cp -a "${S}" "${D}/usr/share/" || die "Copying failed"

	if use java; then
		sed -e  s@__PN__@${P}@g < "${FILESDIR}"/arduino > "${D}/usr/bin/arduino" &&
			chmod +x "${D}/usr/bin/arduino" || die "Creating run script failed"

		# get rid of libraries provided by other packages
		rm -f "${D}/usr/share/${P}/lib/RXTXcomm.jar"
		rm -f "${D}/usr/share/${P}/lib/jna.jar"
		rm -f "${D}/usr/share/${P}/lib/librxtxSerial.so"
		rm -f "${D}/usr/share/${P}/lib/librxtxSerial64.so"
		rm -f "${D}/usr/share/${P}/lib/ecj.jar"

		# use system avrdude
		# patching class files is too hard
		dosym /usr/bin/avrdude "/usr/share/${P}/hardware/tools/avrdude" &&
			dosym /etc/avrdude.conf "/usr/share/${P}/hardware/tools/avrdude.conf" ||
			die "Couldn't symlink system avrdude files"
	fi
}
