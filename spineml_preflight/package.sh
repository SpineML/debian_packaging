#!/bin/bash

################################################################################
#
# Making a debian package of SpineML_PreFlight
#
#
# Don't forget to modify the changelog, to say why the code is being
# packaged again (assuming you're packaging a new version now).
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

PROGRAM_NAME=spineml-preflight
GIT_REPO_DIR=SpineML_PreFlight
VERSION="$1"
DISTRO="$2"

ITPBUG=9999

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
    git clone https://github.com/SpineML/SpineML_PreFlight
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

popd # src/

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
# cp -R ../spineml_preflight-0.1.0.debian_patches debian/patches

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
Build-Depends: debhelper (>= $DEBHELPER_COMPAT_LEVEL.0.0), cmake, cdbs, libpopt-dev, doxygen
Standards-Version: 3.9.3
Homepage: https://github.com/SpineML/SpineML_PreFlight

Package: $PROGRAM_NAME
Architecture: any
Depends: \${shlibs:Depends}, \${misc:Depends}
Description: Simulator independent initial processing for SpineML models
 This code takes a SpineML neural model, probably created in SpineCreator,
 and "preflights" it ready for the simulator, which may be SpineML_2_BRAHMS.
EOF

echo $DEBHELPER_COMPAT_LEVEL > debian/compat

# Two lintian overrides required as brahms installs
# libbrahms-compress.so and libbrahms-channel-sockets.so which are
# dynamically linked and hence fox lintian.
##cat > debian/brahms.lintian-overrides <<EOF
## brahms installs a couple of shared object libraries which are linked
## dynamically by the executable at runtime when it requires them. There
## are no other libraries which are linked to the executable and so the
## call to ldconfig is ineffective and causes
## postinst-has-useless-call-to-ldconfig and
## postrm-has-useless-call-to-ldconfig. This is debhelper bug
## https://bugs.debian.org/204975
#brahms binary: postinst-has-useless-call-to-ldconfig
#brahms binary: postrm-has-useless-call-to-ldconfig
#EOF

# The copyright notice
cat > debian/copyright <<EOF
Format: http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: $PROGRAM_NAME
Source: https://github.com/SpineML/SpineML_PreFlight

# Upstream copyright:
Files: *
Copyright: 2015 Seb James
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
repository at https://github.com/SpineML/SpineML_PreFlight

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

# Now debsign the source:
debsign -S -k"$PACKAGE_MAINTAINER_GPG_KEYID" ${PROGRAM_NAME}_${VERSION}-1_source.changes

. ../build_package
