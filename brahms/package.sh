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

# Our "upstream" tarball will be checked out in ./src
mkdir -p src
pushd src
if [ ! -d $DEBNAME ]; then
    if [ -d ./brahms ]; then
        # Remove and then re-clone
        rm -rf brahms $DEBNAME
    fi
    git clone https://github.com/sebjameswml/brahms
    mv brahms $DEBNAME
else
    cd $DEBNAME
    git pull
fi
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
# Note about debhelper: The debhelper level needs also to be set into debian/compat.
DEBHELPER_COMPAT_LEVEL=9
cat > debian/control <<EOF
Source: $PROGRAM_NAME
Section: science
Priority: optional
Maintainer: $PACKAGE_MAINTAINER_GPG_IDENTITY
Build-Depends: debhelper (>= $DEBHELPER_COMPAT_LEVEL.0.0), python-minimal, python-numpy, python-dev, libxt-dev, libxaw7-dev, cmake, cdbs, libz-dev, pkg-config
Standards-Version: 3.9.3
Homepage: https://github.com/sebjameswml/brahms

Package: $PROGRAM_NAME
Architecture: any
Depends: \${shlibs:Depends}, \${misc:Depends}
Recommends: mpich2, python
Description:  Middleware for integrated systems computation
 Execute models described by SystemML
EOF

echo $DEBHELPER_COMPAT_LEVEL > debian/compat

# Copy in the changelog
if [ ! -f ../brahms_changelog ]; then
    echo "You need to create/update the changelog file"
    exit
fi
cp ../brahms_changelog debian/changelog

# Two lintian overrides required as brahms installs
# libbrahms-compress.so and libbrahms-channel-sockets.so which are
# dynamically linked and hence fox lintian.
cat > debian/brahms.lintian-overrides <<EOF
# brahms installs a couple of shared object libraries which are linked
# dynamically by the executable at runtime when it requires them. There
# are no other libraries which are linked to the executable and so the
# call to ldconfig is ineffective and causes
# postinst-has-useless-call-to-ldconfig and
# postrm-has-useless-call-to-ldconfig. This is debhelper bug
# https://bugs.debian.org/204975
brahms binary: postinst-has-useless-call-to-ldconfig
brahms binary: postrm-has-useless-call-to-ldconfig
EOF

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


# The rules for building.
echo "Doing debian/rules..."
cat > debian/rules <<EOF
#!/usr/bin/make -f
# -*- makefile -*-
export DEB_BUILD_MAINT_OPTIONS = hardening=+all
include /usr/share/cdbs/1/rules/debhelper.mk
include /usr/share/cdbs/1/class/cmake.mk
DEB_CMAKE_EXTRA_FLAGS += -DCMAKE_INSTALL_PREFIX=/usr -DSTANDALONE_INSTALL=OFF -DLICENSE_INSTALL=OFF
EOF
popd

################################################################################
#
# Unpack debian orig source code files
#
#

echo "unpacking $DEBORIG.tar.gz:"
tar xvf $DEBORIG.tar.gz

echo "Ready to build..."
pushd $DEBNAME

echo "Clear CFLAGS etc, so that debian rules will set them up"
unset CPPFLAGS
unset CFLAGS
unset CXXFLAGS
unset LDFLAGS

# I'm using the pbuilder method for building, which is called by the
# pdebuild script. If you change the distribution, then before doing
# this, you have to call the following to create a new distribution
# base tgz:
#
# sudo pbuilder --create --architecture i386 --distribution jessie --basetgz /var/cache/pbuilder/jessie-i386-base.tgz
# sudo pbuilder --create --architecture amd64 --distribution jessie --basetgz /var/cache/pbuilder/jessie-amd64-base.tgz
# (jessie is used as the example here).

#
# Finally, actually call pdebuild for your distro:
#

DISTRO=trusty

pdebuild -- --basetgz /var/cache/pbuilder/$DISTRO-amd64-base.tgz --buildresult /var/cache/pbuilder/$DISTRO-amd64-result
#pdebuild -- --basetgz /var/cache/pbuilder/$DISTRO-i386-base.tgz --buildresult /var/cache/pbuilder/$DISTRO-i386-result

echo "Done. Look in /var/cache/pbuilder/$DISTRO-[i386|amd64]-result/ for the debs"

popd
