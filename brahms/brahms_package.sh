#!/bin/bash

################################################################################
#
# Making a debian package of BRAHMS
#
#

# Before you start, here are the dependencies:
# sudo apt-get install build-essential autoconf automake autotools-dev
#                      dh-make debhelper devscripts fakeroot xutils
#                      lintian pbuilder cdbs
#
# You also need to modify the changelog, to say why the code
# is being packaged again.
#

# Make sure we're using the right umask:
umask 0022

# Some parameters.
export DEBEMAIL="seb.james@sheffield.ac.uk"
export DEBFULLNAME="Sebastian Scott James"
PACKAGE_MAINTAINER_GPG_IDENTITY="$DEBFULLNAME <$DEBEMAIL>"
CURRENT_YEAR=`date +%Y`

# How many processors do we have?
PROCESSORS=`grep "^physical id" /proc/cpuinfo | sort -u | wc -l`
CORES_PER_PROC=`grep "^core id" /proc/cpuinfo | sort -u | wc -l`
CORES=$((PROCESSORS * CORES_PER_PROC))

PROGRAM_NAME=brahms
VERSION=0.7.3

################################################################################
#
# Setting up the package. See http://www.debian.org/doc/manuals/maint-guide/first.en.html
#
#



# The deb source directory will be created with this directory name
DEBNAME=$PROGRAM_NAME"-$VERSION"

# The "orig" tarball will have this name
DEBORIG=$PROGRAM_NAME"_$VERSION.orig"

# Clean up generated tarballs and files
rm -rf $DEBNAME 
rm -f $DEBORIG.tar.gz
rm -f $PROGRAM_NAME"_$VERSION-1.debian.tar.gz"
rm -f $PROGRAM_NAME"_$VERSION-1.dsc"
rm -f $PROGRAM_NAME"_$VERSION-1_amd64.changes"
rm -f $PROGRAM_NAME"_$VERSION-1_i386.changes"
rm -f $PROGRAM_NAME"_$VERSION-1_amd64.deb"
rm -f $PROGRAM_NAME"_$VERSION-1_i386.deb"

# Clean up output files
rm -f $PROGRAM_NAME"_$VERSION-1_amd64.build"
rm -f $PROGRAM_NAME"_$VERSION-1_amd64.deb"
rm -f $PROGRAM_NAME"_$VERSION-1_i386.build"
rm -f $PROGRAM_NAME"_$VERSION-1_i386.deb"
rm -f $PROGRAM_NAME"_$VERSION-1.debian.tar.gz"
rm -f $PROGRAM_NAME"_$VERSION-1_source.changes"

# rmdir hooks

# If we're only to clean up, then stop here.
if [ "x$1" = "xclean" ]; then
    echo "Cleaned up; exiting."
    exit 0
fi

# Our "upstream" tarball is in ../../brahms/
if [ ! -f $DEBNAME.tar.gz ]; then
    echo "Please copy $DEBNAME.tar.gz into the debian_packaging/brahms directory and re-try"
    exit 1
fi

# Clean up our source directory and then create it and pushd into it
mkdir -p $DEBNAME
pushd $DEBNAME

# Run dh_make.
dh_make -s -f ../$DEBNAME.tar.gz

################################################################################
#
# Modifying the source. See http://www.debian.org/doc/manuals/maint-guide/modify.en.html
#
#

# Bugs/patches
cp -R ../brahms-0.7.3.debian_patches debian/patches

################################################################################
#
# Debian files. See http://www.debian.org/doc/manuals/maint-guide/dreq.en.html
#
#

# Remove example files
rm -rf debian/*.ex
rm -rf debian/*.EX

# We don't need a README.Debian file to describe special instructions
# about running this software on Debian.
rm -f debian/README.Debian

# Create the correct control file
# Figure out the dependencies using:
# objdump -p /path/to/exe | grep NEEDED
# And for each line dpkg -S library.so.X
#
# Poss. additional Depends: libxt6, libxaw7
cat > debian/control <<EOF
Source: $PROGRAM_NAME
Section: science
Priority: optional
Maintainer: $PACKAGE_MAINTAINER_GPG_IDENTITY
Build-Depends: debhelper (>= 8.0.0), python-minimal, python-numpy, subversion, libmpich2-dev, python-dev, libxt-dev, libxaw7-dev
Standards-Version: 3.9.3
Homepage: http://brahms.sourceforge.net/home/

Package: $PROGRAM_NAME
Architecture: any
Depends: \${shlibs:Depends}, \${misc:Depends}
Recommends: mpich2, python
Description:  Middleware for integrated systems computation
 Execute models described by StateML
EOF

# Copy in the changelog
if [ ! -f ../brahms_changelog ]; then
    echo "You need to create/update the changelog file"
    exit
fi
cp ../brahms_changelog debian/changelog
 
# and the manpages
if [ ! -f ../brahms.1 ]; then
    echo "You need to create/update the brahms manpage"
    exit
fi
cp ../brahms.1 debian/brahms.1

if [ ! -f ../brahms-execute.1 ]; then
    echo "You need to create/update the brahms-execute manpage"
    exit
fi
cp ../brahms-execute.1 debian/brahms-execute.1

if [ ! -f ../elements_monolithic.1 ]; then
    echo "You need to create/update the elements_monolithic manpage"
    exit
fi
cp ../elements_monolithic.1 debian/elements_monolithic.1


# menu (can be left out - this is legacy (?)
#cat > debian/menu <<EOF
#?package($PROGRAM_NAME):needs="Terminal" section="Applications/Science/Biology"\
#  title="$PROGRAM_NAME" command="/opt/brahms/BRAHMS/bin/$PROGRAM_NAME"
#
#EOF

# The copyright notice
cat > debian/copyright <<EOF
Format: http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: $PROGRAM_NAME
Source: https://http://brahms.sourceforge.net/

# Upstream copyright:
Files: *
Copyright: 2007 Ben Mitchinson
License: GPL-2+
 This package is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 .
 This package is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 .
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>
 .
 On Debian systems, the complete text of the GNU General
 Public License version 2 can be found in "/usr/share/common-licenses/GPL-2".

# Copyright in the package files:
Files: debian/*
Copyright: $CURRENT_YEAR $DEBEMAIL
License: GPL
 This package is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3 of the License, or
 (at your option) any later version.
 .
 This package is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 .
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>
 .
 On Debian systems, the complete text of the GNU General
 Public License version 3 can be found in "/usr/share/common-licenses/GPL-3".
EOF

# The source readme
cat > debian/README.source <<EOF
$PROGRAM_NAME for Debian
-----------------------

This package was produced from a source tarball built from the svn repository
at https://svn.code.sf.net/p/brahms/code/tags/0.7.3

EOF


# The rules for building. Note - custom file here. Created with help from
# https://wiki.debian.org/Courses2005/BuildingWithoutHelper
echo "Doing debian/rules..."
cat > debian/rules <<EOF
#!/usr/bin/make -f
package=brahms

# Function to check if we're in the correct dir
define checkdir
	@test -f debian/rules -a -f framework/engine/base/core.cpp || \
	(echo Not in correct source directory; exit 1)
endef

# Function to check if we're root
define checkroot
	@test \$\$(id -u) = 0 || (echo need root priviledges; exit 1)
endef

# Top directory of the source code (thanks Manoj)
SRCTOP    := \$(shell if [ "\$\$PWD" != "" ]; then echo \$\$PWD; else pwd; fi)
# Destination directory where files will be installed
DESTDIR    = \$(SRCTOP)/debian/\$(package)
# This becomes: /home/seb/greenbrain/debian_packaging/brahms-0.7.3/debian/brahms
#OPT_DIR = \$(DESTDIR)/opt
#INSTALLED_DIR  = \$(DESTDIR)/opt/BRAHMS

# Definition of directories
BIN_DIR = \$(DESTDIR)/usr/bin
# Libs go in a private directory as they're not intended to be shared
# with other projects. Use rpath (best) or LD_LIBRARY_PATH wrapper to
# allow brahms to find em.
LIB_DIR = \$(DESTDIR)/usr/lib/brahms
INCLUDE_DIR = \$(DESTDIR)/usr/include/brahms
SHARE_DIR = \$(DESTDIR)/usr/share/brahms
VAR_LIB_DIR = \$(DESTDIR)/var/lib/brahms
#BINDINGS_DIR = \$(SHARE_DIR)/bindings
DOCS_DIR = \$(DESTDIR)/usr/share/doc/brahms
MAN_DIR = \$(DESTDIR)/usr/share/man/man1
MENU_DIR = \$(DESTDIR)/usr/lib/menu
PIXMAPS_DIR = \$(DESTDIR)/usr/share/pixmaps

# Simple 64/32 bit test for arch bits. Be sure to run pdebuild with linux32.
ARCH_BITS_DETECTED = \${shell uname -m | grep 64}
ifeq (\$(ARCH_BITS_DETECTED), )
ARCH_BITS_DETECTED=32
else
ARCH_BITS_DETECTED=64
endif

# Stamp Rules

configure-stamp:
	\$(checkdir)
#	bash ./configure --prefix=/opt/brahms
	touch configure-stamp

build-stamp: configure-stamp
	\$(checkdir)
	-rm -f build-stamp
	\$(MAKE) all SYSTEMML_MATLAB_PATH=/opt/matlab/R2013a \
	SYSTEMML_TEMP_PATH=/tmp \
	SYSTEMML_BUILD_INSTALL_PATH=\$(DESTDIR)/brahms_build \
	SYSTEMML_INSTALL_PATH='' \
	NOMATLAB=1 \
	ARCH_BITS=\$(ARCH_BITS_DETECTED) \
	NOWX=1
	touch build-stamp

# Debian rules

build: build-stamp

clean: configure-stamp
	\$(checkdir)
	-rm -f *-stamp
	-rm -rf debian/\$(package)
	-rm -f debian/files
	-rm -f debian/substvars

binary-indep: build

# Definitions for install
INST_OWN = -o root -g root
MAKE_DIR  = install -p -d \$(INST_OWN) -m 755
INST_FILE = install -c    \$(INST_OWN) -m 644
INST_PROG = install -c    \$(INST_OWN) -m 755 -s
INST_LIB  = install -c    \$(INST_OWN) -m 644 -s
INST_SCRIPT = install -c  \$(INST_OWN) -m 755

binary-arch: build
	\$(checkdir)
	\$(checkroot)

	# Install Program
	\$(MAKE_DIR) -p \$(BIN_DIR)
	\$(INST_PROG) \$(DESTDIR)/brahms_build/BRAHMS/bin/brahms-execute \$(BIN_DIR)/
	\$(INST_SCRIPT) \$(DESTDIR)/brahms_build/BRAHMS/bin/brahms \$(BIN_DIR)/
	# This program is built in the support directory
	\$(INST_PROG) \$(DESTDIR)/brahms_build/BRAHMS/support/bench/elements/elements_monolithic \$(BIN_DIR)/
	-rm -f \$(DESTDIR)/brahms_build/BRAHMS/support/bench/elements/elements_monolithic

	# Libraries
	\$(MAKE_DIR) -p \$(LIB_DIR)
	\$(INST_LIB) \$(DESTDIR)/brahms_build/BRAHMS/bin/libbrahms-channel-mpich2.so.0.7.3 \$(LIB_DIR)
	ln -s libbrahms-channel-mpich2.so.0.7.3 libbrahms-channel-mpich2.so.0
	mv libbrahms-channel-mpich2.so.0 \$(LIB_DIR)
	ln -s libbrahms-channel-mpich2.so.0.7.3 libbrahms-channel-mpich2.so
	mv libbrahms-channel-mpich2.so \$(LIB_DIR)
	\$(INST_LIB) \$(DESTDIR)/brahms_build/BRAHMS/bin/libbrahms-compress.so.0.7.3 \$(LIB_DIR)
	ln -s libbrahms-compress.so.0.7.3 libbrahms-compress.so.0
	mv libbrahms-compress.so.0 \$(LIB_DIR)
	ln -s libbrahms-compress.so.0.7.3 libbrahms-compress.so
	mv libbrahms-compress.so \$(LIB_DIR)
	\$(INST_LIB) \$(DESTDIR)/brahms_build/BRAHMS/bin/libbrahms-channel-sockets.so.0.7.3 \$(LIB_DIR)
	ln -s libbrahms-channel-sockets.so.0.7.3 libbrahms-channel-sockets.so.0
	mv libbrahms-channel-sockets.so.0 \$(LIB_DIR)
	ln -s libbrahms-channel-sockets.so.0.7.3 libbrahms-channel-sockets.so
	mv libbrahms-channel-sockets.so \$(LIB_DIR)
	\$(INST_LIB) \$(DESTDIR)/brahms_build/BRAHMS/bin/libbrahms-engine.so.0.7.3 \$(LIB_DIR)
	ln -s libbrahms-engine.so.0.7.3 libbrahms-engine.so.0
	mv libbrahms-engine.so.0 \$(LIB_DIR)
	ln -s libbrahms-engine.so.0.7.3 libbrahms-engine.so
	mv libbrahms-engine.so \$(LIB_DIR)

	# Component libraries
	\$(MAKE_DIR) -p \$(LIB_DIR)/bindings/component/1262
	\$(INST_LIB) \$(DESTDIR)/brahms_build/BRAHMS/bindings/component/1262/libbrahms-1262.so.0 \$(LIB_DIR)/bindings/component/1262/
	-rm \$(DESTDIR)/brahms_build/BRAHMS/bindings/component/1262/libbrahms-1262.so.0
	rmdir \$(DESTDIR)/brahms_build/BRAHMS/bindings/component/1262
	rmdir \$(DESTDIR)/brahms_build/BRAHMS/bindings/component

	# include files
	\$(MAKE_DIR) -p \$(INCLUDE_DIR)
	\$(INST_FILE) \$(DESTDIR)/brahms_build/BRAHMS/include/brahms-client.h \$(INCLUDE_DIR)
	\$(INST_FILE) \$(DESTDIR)/brahms_build/BRAHMS/include/brahms-component.h \$(INCLUDE_DIR)
	\$(INST_FILE) \$(DESTDIR)/brahms_build/BRAHMS/include/brahms-1065.h \$(INCLUDE_DIR)
	\$(INST_FILE) \$(DESTDIR)/brahms_build/BRAHMS/include/brahms-1199.h \$(INCLUDE_DIR)
	\$(INST_FILE) \$(DESTDIR)/brahms_build/BRAHMS/include/brahms-1266.h \$(INCLUDE_DIR)

	# bindings
	\$(MAKE_DIR) -p \$(SHARE_DIR)
	cp -Ra \$(DESTDIR)/brahms_build/BRAHMS/bindings \$(SHARE_DIR)/
	chown -R root: \$(SHARE_DIR)/bindings

	# media
	cp -Ra \$(DESTDIR)/brahms_build/BRAHMS/media \$(SHARE_DIR)/
	chown -R root: \$(SHARE_DIR)/media

	# support
	cp -Ra \$(DESTDIR)/brahms_build/BRAHMS/support \$(SHARE_DIR)/
	chown -R root: \$(SHARE_DIR)/support

	# Namespace
	\$(MAKE_DIR) -p \$(VAR_LIB_DIR)
	cp -Ra \$(DESTDIR)/brahms_build/Namespace \$(VAR_LIB_DIR)/
	chown -R root: \$(VAR_LIB_DIR)/Namespace

	# brahms.xml, readme and release notes
	\$(INST_FILE) \$(DESTDIR)/brahms_build/BRAHMS/brahms.xml \$(SHARE_DIR)/

	\$(MAKE_DIR) \$(DESTDIR)/DEBIAN

	# Install Docs
	\$(MAKE_DIR) \$(DOCS_DIR)
	\$(INST_FILE) debian/copyright \$(DOCS_DIR)/copyright
	\$(INST_FILE) debian/changelog \$(DOCS_DIR)/changelog.Debian
	gzip -9 \$(DOCS_DIR)/changelog.Debian
	\$(INST_FILE) \$(DESTDIR)/brahms_build/BRAHMS/README \$(DOCS_DIR)/
	\$(INST_FILE) \$(DESTDIR)/brahms_build/BRAHMS/RELEASE-NOTES \$(DOCS_DIR)/

	# Install Manpages
	\$(MAKE_DIR) \$(MAN_DIR)
	\$(INST_FILE) debian/brahms.1 \$(MAN_DIR)
	gzip -9 \$(MAN_DIR)/brahms.1
	\$(INST_FILE) debian/brahms-execute.1 \$(MAN_DIR)
	gzip -9 \$(MAN_DIR)/brahms-execute.1
	\$(INST_FILE) debian/elements_monolithic.1 \$(MAN_DIR)
	gzip -9 \$(MAN_DIR)/elements_monolithic.1

	# Install Package Management Scripts
	#\$(INST_SCRIPT) debian/postinst \$(DESTDIR)/DEBIAN
	#\$(INST_SCRIPT) debian/postrm \$(DESTDIR)/DEBIAN

	# Compress Docs - nothing here - I compress as I install, above.

	# Clean up the brahms_build dir now (debian/brahms/brahms_build).
	-rm -rf \$(DESTDIR)/brahms_build

	# Work out the shared library dependancies
	echo brahms-execute is here: \$(BIN_DIR)/brahms-execute
	LD_LIBRARY_PATH=\$(LIB_DIR) dpkg-shlibdeps \$(BIN_DIR)/brahms-execute

	# Generate the control file
	dpkg-gencontrol -P\$(DESTDIR)

	# Make DEBIAN/md5sums
	cd \$(DESTDIR) && find . -type f ! -regex '.*DEBIAN/.*' -printf '%P\0' | xargs -r0 md5sum > DEBIAN/md5sums

	# Create the .deb package
	dpkg-deb -b \$(DESTDIR) ../

# Below here is fairly generic really

binary: binary-indep binary-arch

.PHONY: binary binary-arch binary-indep clean build

EOF

popd

################################################################################
#
# Unpack debian orig source code files
#
#

echo "unpacking $DEBORIG.tar.gz:"
tar xvf $DEBORIG.tar.gz

# Set up compiler dpkg-buildflags
export CPPFLAGS=`dpkg-buildflags --get CPPFLAGS`
export CFLAGS=`dpkg-buildflags --get CFLAGS`
export CXXFLAGS=`dpkg-buildflags --get CXXFLAGS`
export LDFLAGS=`dpkg-buildflags --get LDFLAGS`
export DEB_BUILD_HARDENING=1

echo "Ready to build..."
pushd $DEBNAME
#echo " dpkg-buildpackage -j$CORES -rfakeroot"
#dpkg-buildpackage -j -rfakeroot

# pbuilder method for building:
DEB_HOST_ARCH=amd64 DIST=wheezy ARCH=amd64 pdebuild
DEB_HOST_ARCH=i386 DIST=wheezy ARCH=i386 pdebuild

echo "Done. Look in /var/cache/pbuilder/<release>-<arch>/result/ for the debs"

popd
