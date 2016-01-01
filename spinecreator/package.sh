#!/bin/bash

################################################################################
#
# Making a debian package of spinecreator
#

function usage () {
   cat <<EOF

usage: $0 <version>
or     $0 <version> clean

Create Debian package of SpineCreator with given version.

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

VERSION="$1"
DISTRO="$2"
ITPBUG=9999

dt=`date` # Fri, 16 May 2014 15:57:55 +0000
cat > changelog <<EOF
spinecreator ($VERSION-1) UNRELEASED unstable; urgency=low

  * Initial release (Closes: #$ITPBUG)

 -- $DEBFULLNAME <$DEBEMAIL>  Thu, 31 Dec 2015 15:57:55 +0000
EOF

# How many processors do we have?
PROCESSORS=`grep "^physical id" /proc/cpuinfo | sort -u | wc -l`
CORES_PER_PROC=`grep "^core id" /proc/cpuinfo | sort -u | wc -l`
CORES=$((PROCESSORS * CORES_PER_PROC))

################################################################################
#
# Setting up the package. See http://www.debian.org/doc/manuals/maint-guide/first.en.html
#
#
PROGRAM_NAME=spinecreator
GIT_REPO_DIR=SpineCreator

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
# Ensure spec file exists
qmake neuralNetworks.pro -r -spec linux-g++
make clean
popd

popd # from src/

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

# We should have no upstream bugs to fix, as we ARE the upstream maintainers.

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
# NB: I'll add Brahms to the Recommends line, when I've created a
# debian package for it. Or perhaps these would be best in Depends?
#
# extra libs? libgvc6 perhaps. Not perfectly sure of graphviz-dev
# version that we have to be greater than. approx 2.32.
#
# Dependencies will be some of:
# qtdeclarative5-dev, qtdeclarative5-dev-tools, libqt5declarative5,
# qtquick1-5-dev, qtscript5-dev, libqt5svg5-dev, qttools5-dev-tools,
# qttools5-dev, libqt5opengl5-dev, qtquick1-qml-plugins
#
cat > debian/control <<EOF
Source: spinecreator
Section: x11
Priority: optional
Maintainer: $PACKAGE_MAINTAINER_GPG_IDENTITY
Build-Depends: debhelper (>= 8.0.0), libc6-dev, libstdc++-dev, libglu1-mesa-dev, python2.7-dev, cdbs, graphviz-dev (>= 2.32.0), qt5-qmake, qttools5-dev, qttools5-dev-tools, libqt5opengl5-dev, libqt5svg5-dev, qt5-default
Standards-Version: 3.9.3
Homepage: http://bimpa.group.shef.ac.uk/SpineML/index.php/SpineCreator_-_A_Graphical_Tool

Package: spinecreator
Architecture: any
Depends: \${shlibs:Depends}, \${misc:Depends}, spineml-preflight
Recommends: xsltproc, gcc, spineml-2-brahms
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
if [ ! -f /var/cache/pbuilder/$DISTRO-i386-base.tgz ]; then
    echo "Create i386 pbuilder base.tgz"
    sudo pbuilder --create --architecture i386 --distribution $DISTRO --basetgz /var/cache/pbuilder/$DISTRO-i386-base.tgz
fi

if [ ! -f /var/cache/pbuilder/$DISTRO-amd64-base.tgz ]; then
    echo "Create amd64 pbuilder base.tgz"
    sudo pbuilder --create --architecture amd64 --distribution $DISTRO --basetgz /var/cache/pbuilder/$DISTRO-amd64-base.tgz
fi

#
# Finally, actually call pdebuild for your distro:
#

pdebuild -- --basetgz /var/cache/pbuilder/$DISTRO-amd64-base.tgz --buildresult /var/cache/pbuilder/$DISTRO-amd64-result
pdebuild -- --basetgz /var/cache/pbuilder/$DISTRO-i386-base.tgz --buildresult /var/cache/pbuilder/$DISTRO-i386-result

echo "Done. Look in /var/cache/pbuilder/$DISTRO-[i386|amd64]-result/ for the debs"

popd
