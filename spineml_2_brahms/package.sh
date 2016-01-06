#!/bin/bash

################################################################################
#
# Making a debian package of SpineML_2_BRAHMS
#
#
# Don't forget to modify the changelog, to say why the code is being
# packaged again (assuming you're packaging a new version now).
#
# NB: This BuildDepends on brahms. Follow
#
# https://wiki.debian.org/PbuilderTricks#How_to_include_local_packages_in_the_build
# to set up a local package archive.
#

# Make sure we're using the right umask:
umask 0022

# The package maintainer parameters.
. ../package_maintainer.sh

# Get version, distro, git branch from the command line
if [ -z $2 ]; then
    echo "usage: package.sh version distro <branch>"
    echo "(branch defaults to 'master' if omitted)"
    exit
fi
GIT_BRANCH_REQUEST="master"
if [ ! -z $3 ]; then
    GIT_BRANCH_REQUEST="$3"
fi

PROGRAM_NAME=spineml-2-brahms
GIT_REPO_DIR=SpineML_2_BRAHMS
VERSION="$1"
DISTRO="$2"

ITPBUG=742517

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
    if [ -d ./$GIT_REPO_DIR ]; then
        # Remove and then re-clone
        rm -rf $GIT_REPO_DIR $DEBNAME
    fi
    git clone https://github.com/SpineML/$GIT_REPO_DIR
    mv $GIT_REPO_DIR $DEBNAME
    pushd $DEBNAME
    git checkout -b $GIT_BRANCH_REQUEST
    popd
else
    pushd $DEBNAME
    git checkout $GIT_BRANCH_REQUEST
    git pull
    popd
fi

pushd $DEBNAME
# Get git revision information
GIT_BRANCH=`git branch| grep \*| awk -F' ' '{ print $2; }'`
GIT_LAST_COMMIT_SHA=`git log -1 --oneline | awk -F' ' '{print $1;}'`
GIT_LAST_COMMIT_DATE=`git log -1 | grep Date | awk -F 'Date:' '{print $2;}'| sed 's/^[ \t]*//'`
popd

popd # src

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

# Bugs/patches would go here.
# cp -R ../spineml_2_brahms-0.1.0.debian_patches debian/patches

# Remove example files
rm -rf debian/*.ex
rm -rf debian/*.EX

# We don't need a README.Debian file to describe special instructions
# about running this software on Debian.
rm -f debian/README.Debian

# Create the fresh debian/changelog.
rm -f debian/changelog
debchange --create --package $PROGRAM_NAME --closes $ITPBUG \
          --distribution $DISTRO --urgency low --newversion ${VERSION}-1

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
Build-Depends: debhelper (>= $DEBHELPER_COMPAT_LEVEL.0.0), cmake, cdbs, brahms
Standards-Version: 3.9.3
Homepage: https://github.com/SpineML/SpineML_2_BRAHMS

Package: $PROGRAM_NAME
Architecture: any
Depends: \${shlibs:Depends}, \${misc:Depends}, brahms
Description: SpineML to BRAHMS execution backend
 Code generation scripts for transforming a SpineML neural model into
 a running BRAHMS system. This includes XSL scripts to convert a
 SpineML model into SystemML format with compiled components. The
 scripts convert SpineML component XML into C++ code which is then
 compiled into shared object code. Converts SpineML network and
 experiment XML into the SystemML XML. Finally, the simulation is
 executed.
EOF

echo $DEBHELPER_COMPAT_LEVEL > debian/compat

# The copyright notice
cat > debian/copyright <<EOF
Format: http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: $PROGRAM_NAME
Source: https://github.com/SpineML/SpineML_2_BRAHMS

# Upstream copyright:
Files: *
Copyright: 2015 Alex Cope, Seb James
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
-------------------------------

This package was produced from a source tarball automatically built from the git
repository at https://github.com/SpineML/SpineML_2_BRAHMS

The git commit revision is: $GIT_LAST_COMMIT_SHA of $GIT_LAST_COMMIT_DATE on
the $GIT_BRANCH branch.
EOF


# The rules for building.
echo "Doing debian/rules..."
cat > debian/rules <<EOF
#!/usr/bin/make -f
# -*- makefile -*-
export DEB_BUILD_MAINT_OPTIONS = hardening=+all
include /usr/share/cdbs/1/rules/debhelper.mk
include /usr/share/cdbs/1/class/cmake.mk
DEB_CMAKE_EXTRA_FLAGS += -DCMAKE_INSTALL_PREFIX=/usr
EOF
popd

. ../build_package
