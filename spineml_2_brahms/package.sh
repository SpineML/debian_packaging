#!/bin/bash

################################################################################
#
# Making a debian package of the SpineML to Brahms scripts
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

function usage () {
   cat <<EOF

usage: $0 <version>
or     $0 <version> clean

Create Debian package of SpineML_2_BRAHMS with given version.

Provide clean as the second argument to clean up all generated files for the
given version.

EOF
   exit 0
}

umask 0022
# Avoid gcc-4.8 from /usr/local/bin (this is for circle):
export PATH=/usr/bin:/bin

# Some parameters.
export DEBEMAIL="seb.james@sheffield.ac.uk"
export DEBFULLNAME="Sebastian Scott James"
PACKAGE_MAINTAINER_GPG_IDENTITY="$DEBFULLNAME <$DEBEMAIL>"
CURRENT_YEAR=`date +%Y`

# Check we're being called the right way.
if [ -z "$1" ]; then
    usage
fi

# Catch an easy-to-make error:
if [ "x$1" = "clean" ]; then
    usage
fi

PROGRAM_NAME=spineml-2-brahms
VERSION="$1"

# How many processors do we have?
PROCESSORS=`grep "^physical id" /proc/cpuinfo | sort -u | wc -l`
CORES_PER_PROC=`grep "^core id" /proc/cpuinfo | sort -u | wc -l`
CORES=$((PROCESSORS * CORES_PER_PROC))

# Ensure that the upstream is autoreconfed - that configure exists
pushd ~/greenbrain/SpineML_2_BRAHMS
#make clean
if [ ! -f configure ]; then
    autoreconf -is
fi
popd

################################################################################
#
# Setting up the package. See http://www.debian.org/doc/manuals/maint-guide/first.en.html
#
#

# The upstream directory name. What the spineml-2-brahms tarball unpacks to.
UPSTREAM_NAME=SpineML_2_BRAHMS

# The deb source directory will be created with this directory name
DEBNAME=$PROGRAM_NAME"-$VERSION"

# The "orig" tarball will have this name
DEBORIG=$PROGRAM_NAME"_$VERSION.orig"

# Clean up generated tarballs and files
rm -rf $DEBNAME 

# For now, we clean the source file so it rebuilds from upstream each time:
rm -f $DEBNAME.tar.gz

rm -f $DEBORIG.tar.gz
rm -f $PROGRAM_NAME"_$VERSION-1.debian.tar.gz"
rm -f $PROGRAM_NAME"_$VERSION-1.dsc"
rm -f $PROGRAM_NAME"_$VERSION-1_amd64.changes"
rm -f $PROGRAM_NAME"_$VERSION-1_i386.changes"
rm -f $PROGRAM_NAME"_$VERSION-1_amd64.deb"
rm -f $PROGRAM_NAME"_$VERSION-1_i386.deb"
rm -f $PROGRAM_NAME"_$VERSION-1_amd64.build"
rm -f $PROGRAM_NAME"_$VERSION-1_i386.build"
rm -f $PROGRAM_NAME"_$VERSION-1_source.changes"

# If we're only to clean up, then stop here.
if [ "x$2" = "xclean" ]; then
    echo "Cleaned up; exiting."
    exit 0
fi

if [ ! -f $DEBNAME.tar.gz ]; then

    echo "Building $DEBNAME.tar.gz..."

    if [ -d ~/greenbrain/$UPSTREAM_NAME ]; then

        echo "We have access to ../../$UPSTREAM_NAME - the upstream source."

        # Create our "upstream" tarball from the git repo
        rm -rf /tmp/$DEBNAME
        # Note: tarball name has to be pkgname-version:
        cp -Ra ~/greenbrain/$UPSTREAM_NAME /tmp/$DEBNAME
        tar czf $DEBNAME.tar.gz --exclude-vcs -C/tmp $DEBNAME

    else 
        echo "Please find spineml-2-brahms.tar.gz (the upstream version) and retry"
        exit 1
    fi
else
    echo "$DEBNAME.tar.gz already exists, using that."
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

# Bugs/patches. Probably none - we have access to upstream source.
#cp -R ../$DEBNAME.debian_patches debian/patches

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
cat > debian/control <<EOF
Source: $PROGRAM_NAME
Section: science
Priority: optional
Maintainer: $PACKAGE_MAINTAINER_GPG_IDENTITY
Build-Depends: debhelper (>= 8.0.0), brahms (= 0.7.3-1), cdbs (>= 0.4.115), automake (>= 1:1.11.6), libtool (>= 2.4.2)
Standards-Version: 3.9.3
Homepage: http://bimpa.group.shef.ac.uk/SpineML/index.php/Brahms

Package: $PROGRAM_NAME
Architecture: any
Depends: \${shlibs:Depends}, \${misc:Depends}, brahms (= 0.7.3-1), xsltproc, build-essential
Description:  Scripts and a Brahms component Namespace for SpineML-described models.
 These scripts take SpineML input and generate a Brahms namespace of components
 which can be used to execute the model.
EOF

# Copy in the changelog
if [ ! -f ../spineml-2-brahms_changelog ]; then
    echo "You need to create/update the changelog file"
    exit
fi
cp ../spineml-2-brahms_changelog debian/changelog

# Man page for spineml-2-brahms is contained within the source code.
# and the manpages
# 
#if [ ! -f ../convert_script_s2b.1 ]; then
#    echo "You need to create/update the spineml-2-brahms manpage"
#    exit
#fi
#cp ../convert_script_s2b.1 debian/convert_script_s2b.1

# The copyright notice
cat > debian/copyright <<EOF
Format: http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: $PROGRAM_NAME
Source: http://bimpa.group.shef.ac.uk/SpineML/index.php/Brahms

# Upstream copyright:
Files: *
Copyright: 2013 Alex Cope
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

This package was produced from a source archive provided by Alex Cope and available
from http://bimpa.group.shef.ac.uk/SpineML/index.php/Brahms

EOF


# The rules for building. Note - custom file here. Created with help from
# https://wiki.debian.org/Courses2005/BuildingWithoutHelper
echo "Doing debian/rules..."
cat > debian/rules <<EOF
#!/usr/bin/make -f
include /usr/share/cdbs/1/rules/debhelper.mk
include /usr/share/cdbs/1/class/autotools.mk
# There are some minor issues in the build - when these are fixed, this can be removed:
DEB_CONFIGURE_EXTRA_FLAGS := --disable-warnings-are-errors
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
#dpkg-buildpackage -j$CORES -rfakeroot

DEB_HOST_ARCH=amd64 DIST=wheezy ARCH=amd64 pdebuild
DEB_HOST_ARCH=i386 DIST=wheezy ARCH=i386 pdebuild

echo "Done. Look in /var/cache/pbuilder/<release>-<arch>/result/ for the debs"

popd
