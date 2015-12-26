#!/bin/bash

# Supercedes brahms_package.sh. Packages the git-revision-controlled
# version of brahms, which has a cmake build process. Consequently,
# this should be a lot simpler.

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
VERSION=0.8.0

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

# Our "upsream" tarball will be checked out in ./src
mkdir -p src
pushd src
if [ ! -d $DEBNAME ]; then
    if [ -d ./brahms ]; then
        # Remove and then re-clone
        rm -rf brahms $DEBNAME
    fi
    git clone https://github.com/sebjameswml/brahms
    mv brahms $DEBNAME
fi # else do nothing for now
popd

# Now create $DEBNAME.tar.gz
if [ -f $DEBNAME.tar.gz ]; then
    rm -f $DEBNAME.tar.gz
fi

tar czf $DEBNAME.tar.gz --exclude-vcs -C./src $DEBNAME

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

# Bugs/patches not presently required; have control over source.
# cp -R ../brahms-0.7.3.debian_patches debian/patches

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
Build-Depends: debhelper (>= 8.0.0), python-minimal, python-numpy, subversion, libmpich2-dev, python-dev, libxt-dev, libxaw7-dev, cmake, cdbs, libz-dev, pkg-config
Standards-Version: 3.9.3
Homepage: https://github.com/sebjameswml/brahms

Package: $PROGRAM_NAME
Architecture: any
Depends: \${shlibs:Depends}, \${misc:Depends}, libz1, libxt6, libxext6, libxaw7, libx11-6, libxpm4, libxau6, libxcb1, libice6
Recommends: mpich2, python
Description:  Middleware for integrated systems computation
 Execute models described by SystemML
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

This package was produced from a source tarball automatically built from the git
repository at https://github.com/sebjameswml/brahms

EOF


# The rules for building. Note - custom file here. Created with help from
# https://wiki.debian.org/Courses2005/BuildingWithoutHelper
echo "Doing debian/rules..."
cat > debian/rules <<EOF
#!/usr/bin/make -f
# -*- makefile -*-
include /usr/share/cdbs/1/rules/debhelper.mk
include /usr/share/cdbs/1/class/cmake.mk
DEB_CMAKE_EXTRA_FLAGS += -DCMAKE_INSTALL_PREFIX=/usr -DSTANDALONE_INSTALL=OFF
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

# pbuilder method for building. If you change the DIST, then before
# doing this, you have to call
#
# sudo pbuilder --create --architecture i386 --distribution jessie --basetgz /var/cache/pbuilder/jessie-i386-base.tgz
# sudo pbuilder --create --architecture amd64 --distribution jessie --basetgz /var/cache/pbuilder/jessie-amd64-base.tgz
# (jessie used as the example here).

#DEB_HOST_ARCH=amd64 DIST=wheezy ARCH=amd64 pdebuild
#DEB_HOST_ARCH=i386 DIST=wheezy ARCH=i386 pdebuild

#DEB_HOST_ARCH=amd64 DIST=jessie ARCH=amd64 pdebuild -- --basetgz /var/cache/pbuilder/jessie-amd64-base.tgz

DEB_HOST_ARCH=i386 DIST=jessie ARCH=i386 pdebuild -- --basetgz /var/cache/pbuilder/jessie-i386-base.tgz


echo "Done. Look in /var/cache/pbuilder/<release>-<arch>/result/ for the debs"

popd
