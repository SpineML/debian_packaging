#!/bin/bash

################################################################################
#
# Updating a debian package of spinecreator, assuming the only changes
# are in the debian packaging - i.e. the upstream release hasn't
# changed, is the same version, and so on.
#

function usage () {
   cat <<EOF

usage: $0 srcversion prevpkgversion distro <branch>

Branch defaults to 'master' if omitted.

Update and existing Debian package of SpineCreator with given version.

EOF
   exit 0
}

umask 0022
# Avoid gcc-4.8 from /usr/local/bin (this is for circle):
export PATH=/usr/bin:/bin

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

################################################################################
#
# Setting up the package. See http://www.debian.org/doc/manuals/maint-guide/first.en.html
#
#
PROGRAM_NAME=spinecreator
GIT_REPO_DIR=SpineCreator

# The deb source directory will be created with this directory name
DEBNAME=${PROGRAM_NAME}-${VERSION}

# The "orig" tarball will have this name
DEBORIG=${PROGRAM_NAME}_${VERSION}.orig
# dh_make created this; I need to figure out how to do so.

# Clean up generated tarballs and files ready to re-create from the
# git repo and the debian file.
rm -rf $DEBNAME

# When updating a package this way, we can't update the upstream
# source, instead we can only create debian patches. So I've omitted
# the git stuff here.

tar xvf ${DEBNAME}_${PREVDEBVERSION}.orig.tar.gz

pushd $DEBNAME
# Unpack previous package version debian directory
tar xvf ../${PROGRAM_NAME}_${PREVDEBVERSION}.debian.tar.gz

# Create the fresh debian/changelog.
debchange --package $PROGRAM_NAME \
    --distribution $DISTRO --urgency low --increment

#
# Now re-create numerous debian files
#

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
Depends: \${shlibs:Depends}, \${misc:Depends}
Recommends: xsltproc, gcc, spineml-2-brahms
Description:  GUI for SpineML.
 Create, visualise and simulate networks of point spiking neural models.
 For use with the SpineML XML format and compatible simulators.
EOF

# Debian menu (distinct from the applications/spinecreator.desktop
# generated menu)
cat > debian/menu <<EOF
?package(spinecreator):needs="X11" section="Applications/Science/Biology"\
  title="SpineCreator" command="spinecreator" icon="/usr/share/pixmaps/spinecreator.xpm"

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

# Don't update the source readme; the source is not allowed to change.

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

echo "EXIT FOR DEBUG"
exit

echo "build_package..."
. ../build_package
