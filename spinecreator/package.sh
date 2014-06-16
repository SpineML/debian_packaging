#!/bin/bash

################################################################################
#
# Making a debian package of spinecreator
#
#

# Before you start, here are the dependencies:
# sudo apt-get install build-essential autoconf automake autotools-dev
#                      dh-make debhelper devscripts fakeroot xutils
#                      lintian pbuilder cdbs
#
# You also need to modify changelog.spinecreator, to say why the code
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
PACKAGE_MAINTAINER_GPG_IDENTITY="DEBFULLNAME <$DEBEMAIL>"
CURRENT_YEAR=`date +%Y`

# Check we're being called the right way.
if [ -z "$1" ]; then
    usage
fi
if [ "x$1" = "xclean" ]; then
    usage
fi

VERSION="$1"

# Get git revision information
pushd ~/greenbrain/SpineCreator
GIT_BRANCH=`git branch| grep \*| awk -F' ' '{ print $2; }'`
GIT_LAST_COMMIT_SHA=`git log -1 --oneline | awk -F' ' '{print $1;}'`
GIT_LAST_COMMIT_DATE=`git log -1 | grep Date | awk -F 'Date:' '{print $2;}'| sed 's/^[ \t]*//'`
popd

# How many processors do we have?
PROCESSORS=`grep "^physical id" /proc/cpuinfo | sort -u | wc -l`
CORES_PER_PROC=`grep "^core id" /proc/cpuinfo | sort -u | wc -l`
CORES=$((PROCESSORS * CORES_PER_PROC))

# Ensure spec file exists
pushd ~/greenbrain/SpineCreator
qmake-qt4 neuralNetworks.pro -r -spec linux-g++
make clean
popd

################################################################################
#
# Setting up the package. See http://www.debian.org/doc/manuals/maint-guide/first.en.html
#
#
PROGRAM_NAME=spinecreator
# The deb source directory will be created with this directory name
DEBNAME=$PROGRAM_NAME-$VERSION

# The "orig" tarball will have this name
DEBORIG=$PROGRAM_NAME"_$VERSION.orig"

# Clean up generated tarballs and files
rm -rf $DEBNAME
rm -f $DEBNAME.tar.gz
rm -f $DEBORIG.tar.gz
rm -f $PROGRAM_NAME"_$VERSION-1.debian.tar.gz"
rm -f $PROGRAM_NAME"_$VERSION-1.dsc"
rm -f $PROGRAM_NAME"_$VERSION-1_amd64.changes"
rm -f $PROGRAM_NAME"_$VERSION-1_amd64.deb"
rm -f $PROGRAM_NAME"_$VERSION-1_amd64.build"
rm -f $PROGRAM_NAME"_$VERSION-1_i386.changes"
rm -f $PROGRAM_NAME"_$VERSION-1_i386.deb"
rm -f $PROGRAM_NAME"_$VERSION-1_i386.build"
rm -f $PROGRAM_NAME"_$VERSION-1_source.changes"

# Remove temporary "upstream tarball" created from the git repo
rm -rf /tmp/$DEBNAME

# If we're only to clean up, then stop here.
if [ "x$2" = "xclean" ]; then
    echo "Cleaned up; exiting."
    exit 0
fi

# Create our "upstream" tarball from the git repo
cp -Ra ~/greenbrain/SpineCreator /tmp/$DEBNAME # Note: SpineCreator tarball has to be spinecreator-0.9.3
tar czf $DEBNAME.tar.gz --exclude-vcs -C/tmp $DEBNAME

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

# NB: We should have no upstream bugs to fix, as we ARE the upstream maintainers.

################################################################################
#
# Debian files. See http://www.debian.org/doc/manuals/maint-guide/dreq.en.html
#
#

# Remove example files
rm -rf debian/*.ex
rm -rf debian/*.EX

# We don't need a README.Debian file to describe special instructions
# about running this softare on Debian.
rm -f debian/README.Debian

# Create the correct control file
# Figure out the dependencies using:
# objdump -p /path/to/spinecreator | grep NEEDED
# And for each line dpkg -S library.so.X
#
# NB: I'll add Brahms to the Recommends line, when I've created a debian package for it.
#
cat > debian/control <<EOF
Source: spinecreator
Section: x11
Priority: optional
Maintainer: $PACKAGE_MAINTAINER_GPG_IDENTITY
Build-Depends: debhelper (>= 8.0.0), qt4-qmake, libc6-dev, libstdc++-dev, libglu1-mesa-dev, libqt4-dev, libqt4-opengl-dev, libgvc5, libgraph4, python2.7-dev, cdbs, graphviz-dev (>= 2.26.3)
Standards-Version: 3.9.3
Homepage: http://bimpa.group.shef.ac.uk/SpineML/index.php/SpineCreator_-_A_Graphical_Tool

Package: spinecreator
Architecture: any
Depends: \${shlibs:Depends}, \${misc:Depends}
Recommends: xsltproc, gcc
Description:  GUI for SpineML.
 Create, visualise and simulate networks of point spiking neural models.
 For use with the SpineML XML format and compatible simulators.
EOF

# A function for copying files in from the source tree (ones stored in package/debian/)
copyin()
{
    if [ -z "$1" ]; then
        echo "Call copyin with 1 argument."
        exit
    fi
    THEFILE="$1"
    if [ ! -f ~/greenbrain/debian_packaging/spinecreator/$THEFILE ]; then
        echo "You need to create/update the $THEFILE file (in the debian_packaging repo)"
        exit
    fi
    cat ~/greenbrain/debian_packaging/spinecreator/$THEFILE > debian/$THEFILE
}

# Copy in the changelog
copyin "changelog"

# and the manpage
copyin "spinecreator.1"

# menu
cat > debian/menu <<EOF
?package(spinecreator):needs="X11" section="Applications/Science/Biology"\
  title="spinecreator" command="/usr/bin/spinecreator"

EOF

# The copyright notice
cat > debian/copyright <<EOF
Format: http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: spinecreator
Source: https://github.com/SpineML/SpineCreator

# Upstream copyright:
Files: *
Copyright: 2013-2014 Alex Cope <a.cope@sheffield.ac.uk>
                     Paul Richmond <p.richmond@sheffield.ac.uk>
                     Seb James <seb.james@sheffield.ac.uk>
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
spinecreator for Debian
-----------------------

This package was produced from a source tarball built from the git repository
at https://github.com/SpineML/SpineCreator.

The git commit revision is: $GIT_LAST_COMMIT_SHA of $GIT_LAST_COMMIT_DATE on
the $GIT_BRANCH branch.
EOF

# The rules for building. Note - using cdbs here.
cat > debian/rules <<EOF
#!/usr/bin/make -f
include /usr/share/cdbs/1/rules/debhelper.mk

# The following is:
#  include /usr/share/cdbs/1/class/qmake.mk
# with https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=695367 applied
# and the comments stripped out.

_cdbs_scripts_path ?= /usr/lib/cdbs
_cdbs_rules_path ?= /usr/share/cdbs/1/rules
_cdbs_class_path ?= /usr/share/cdbs/1/class

ifndef _cdbs_class_qmake
_cdbs_class_qmake = 1

include \$(_cdbs_class_path)/makefile.mk\$(_cdbs_makefile_suffix)

# FIXME: Restructure to allow early override
DEB_MAKE_EXTRA_ARGS = \$(DEB_MAKE_PARALLEL)

DEB_MAKE_INSTALL_TARGET = install INSTALL_ROOT=\$(DEB_DESTDIR)
DEB_MAKE_CLEAN_TARGET = distclean

QMAKE ?= qmake

ifneq (,\$(filter nostrip,\$(DEB_BUILD_OPTIONS)))
DEB_QMAKE_CONFIG_VAL ?= nostrip
endif

common-configure-arch common-configure-indep:: common-configure-impl
common-configure-impl:: \$(DEB_BUILDDIR)/Makefile
\$(DEB_BUILDDIR)/Makefile:
	cd \$(DEB_BUILDDIR) && \$(QMAKE) \$(DEB_QMAKE_ARGS) \$(if \$(DEB_QMAKE_CONFIG_VAL),'CONFIG += \$(DEB_QMAKE_CONFIG_VAL)') 'QMAKE_CC = \$(CC)' 'QMAKE_CXX = \$(CXX)' 'QMAKE_CFLAGS_RELEASE = \$(CPPFLAGS) \$(CFLAGS)' 'QMAKE_CXXFLAGS_RELEASE = \$(CPPFLAGS) \$(CXXFLAGS)' 'QMAKE_LFLAGS_RELEASE = \$(LDFLAGS)'

clean::
	rm -f \$(DEB_BUILDDIR)/Makefile \$(DEB_BUILDDIR)/.qmake.internal.cache

endif

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

echo "Ready to build. Pushing into $DEBNAME"
pushd $DEBNAME

# You can do a simple build for the current platform like this:
# dpkg-buildpackage -j$CORES -rfakeroot

DEB_HOST_ARCH=amd64 DIST=wheezy ARCH=amd64 pdebuild
DEB_HOST_ARCH=i386 DIST=wheezy ARCH=i386 pdebuild

echo "Done. Look in /var/cache/pbuilder/<release>-<arch>/result/ for the debs"

popd
