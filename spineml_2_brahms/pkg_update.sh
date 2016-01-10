#!/bin/bash

################################################################################
#
# Updating a debian package of SpineML_2_BRAHMS
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

function usage () {
   cat <<EOF

usage: $0 srcversion prevpkgversion distro <branch>

Branch defaults to 'master' if omitted.

Update and existing Debian package of SpineCreator with given version.

EOF
   exit 0
}

# Make sure we're using the right umask:
umask 0022

# The package maintainer parameters.
. ../package_maintainer.sh

# Get version, distro, git branch from the command line
if [ -z $3 ]; then
    usage
    exit
fi
GIT_BRANCH_REQUEST="master"
if [ ! -z $4 ]; then
    GIT_BRANCH_REQUEST="$4"
fi

VERSION="$1"
PREVDEBVERSION="$2"
DISTRO="$3"

PROGRAM_NAME=spineml-2-brahms
GIT_REPO_DIR=SpineML_2_BRAHMS

# The deb source directory will be created with this directory name
DEBNAME=${PROGRAM_NAME}-${VERSION}

# The "orig" tarball will have this name
DEBORIG=${PROGRAM_NAME}_${VERSION}.orig

# Clean up generated tarballs and files
rm -rf $DEBNAME 

# Unpack the debian orig file:
tar xvf ${DEBORIG}.tar.gz

pushd $DEBNAME
echo -n "PWD: "
pwd

echo "Extract ${DEBNAME}_${PREVDEBVERSION}.orig.tar.gz..."
# Unpack previous package version debian directory
tar xvf ../${PROGRAM_NAME}_${PREVDEBVERSION}.debian.tar.gz

# Create the fresh debian/changelog.
debchange --package $PROGRAM_NAME \
    --distribution $DISTRO --urgency low --increment

# Determine the new Debian version from the first line of the newly
# created changelog.
NEWDEBVERSION_part2=`head -n1 ${DEBNAME}/debian/changelog | grep ${VERSION} | awk -F "[(]${VERSION}" '{ print $2; }'| awk -F '[)]' '{ print $1; }' | awk -F '-' '{ print $2; }'`
NEWDEBVERSION=${VERSION}-${NEWDEBVERSION_part2}

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
Depends: \${shlibs:Depends}, \${misc:Depends}, brahms, spineml-preflight
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

# Source readme doesn't change for a packaging-only update

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
