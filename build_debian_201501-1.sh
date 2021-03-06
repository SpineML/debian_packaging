#!/bin/bash

# This script should simply build a set of .debs from an existing set of
# source packages. The source packages should be done manually, one by one.
echo "Now out of date. package.sh needs to be changed for pkg_justbuild.sh"
exit 1

# Builds all 4 packages for a Debian distro (e.g. Jessie)

# IMPORTANT: Set
# MIRRORSITE=http://ftp.uk.debian.org/debian/
# in /etc/pbuilderrc
ms=`egrep ^MIRRORSITE /etc/pbuilderrc|grep debian.org/debian`
if [ x"$ms" = "x" ]; then
    echo "Set MIRRORSITE=http://ftp.uk.debian.org/debian/ in /etc/pbuilderrc"
    exit
fi

# To run this, you need to have set up local package dependencies, with this
# in /etc/pbuilderrc:
#
## How to include local packages in the build:
#OTHERMIRROR="deb [trusted=yes] file:///var/cache/pbuilder/localdeps ./"
#BINDMOUNTS="/var/cache/pbuilder/localdeps"
## the hook dir may already be set/populated!
#HOOKDIR="/var/cache/pbuilder/hookd"
## this is necessary for running ''apt-ftparchive'' in the hook below
#EXTRAPACKAGES="apt-utils"
#
# And this in /var/cache/pbuilder/hookd:
#
#s@host:~$ cat /var/cache/pbuilder/hookd/D05deps 
##!/bin/bash
#echo "D05deps script"
#(cd /var/cache/pbuilder/localdeps; apt-ftparchive packages . > Packages)
#apt-get update
#
# This has to be included BEFORE the base.tgz files are built.
#
# Resulting source package data is in the package subdirectories here
# (brahms, spineml_2_brahms, etc). Finished binary packages should be
# found in /var/cache/pbuilder/localdeps and also in the
# pbuilder/$DISTRO-amd64/i386-results directories

# What versions/branches?
if [ -z "$1" ]; then
    echo "Pass in distro tag (jessie or unstable etc)"
    exit
fi

# What versions/branches?
DISTRO="$1"

BRAHMS_VER=0.8.0
BRAHMS_BR=release-$BRAHMS_VER
BRAHMS_ITPBUG=742518 # Not yet passed into package.sh

S2B_VER=1.1.0
S2B_BR=release-$S2B_VER
S2B_ITPBUG=742517 # Not yet passed in

SPF_VER=0.1.0
SPF_BR=release-$SPF_VER
SPF_ITPBUG=9999 # Not real

SC_VER=0.9.5
SC_BR=release-$SC_VER
SC_ITPBUG=9999 # Not real

# Make sure that jessie base.tgz files exist:
if [ ! -f /var/cache/pbuilder/$DISTRO-i386-base.tgz ]; then
    sudo pbuilder --create --architecture i386 --distribution ${DISTRO} --basetgz /var/cache/pbuilder/${DISTRO}-i386-base.tgz --debootstrapopts "--keyring=/usr/share/keyrings/debian-archive-keyring.gpg"
fi
if [ ! -f /var/cache/pbuilder/$DISTRO-amd64-base.tgz ]; then
    sudo pbuilder --create --architecture amd64 --distribution ${DISTRO} --basetgz /var/cache/pbuilder/${DISTRO}-amd64-base.tgz --debootstrapopts "--keyring=/usr/share/keyrings/debian-archive-keyring.gpg"
fi

exit 0

# Build BRAHMS
pushd brahms
./package.sh ${BRAHMS_VER} ${DISTRO} ${BRAHMS_BR}
sudo cp /var/cache/pbuilder/${DISTRO}-amd64-result/brahms_${BRAHMS_VER}-1_amd64.deb \
   /var/cache/pbuilder/localdeps/
if [ "$?" -ne 0 ]; then
    echo "Failed to copy amd64.deb into localdeps directory"
    exit
fi
sudo cp /var/cache/pbuilder/${DISTRO}-i386-result/brahms_${BRAHMS_VER}-1_i386.deb \
   /var/cache/pbuilder/localdeps/
if [ "$?" -ne 0 ]; then
    echo "Failed to copy i386.deb into localdeps directory"
    exit
fi
popd

# Build SpineML_PreFlight
pushd spineml_preflight
./package.sh ${SPF_VER} ${DISTRO} ${SPF_BR}
sudo cp /var/cache/pbuilder/${DISTRO}-amd64-result/spineml-preflight_${SPF_VER}-1_amd64.deb \
    /var/cache/pbuilder/localdeps/
if [ "$?" -ne 0 ]; then
    echo "Failed to copy amd64.deb into localdeps directory"
    exit
fi
sudo cp /var/cache/pbuilder/${DISTRO}-i386-result/spineml-preflight_${SPF_VER}-1_i386.deb \
    /var/cache/pbuilder/localdeps/
if [ "$?" -ne 0 ]; then
    echo "Failed to copy i386.deb into localdeps directory"
    exit
fi
popd

# Build SpineML_2_BRAHMS (which depends on BRAHMS and SpineML_PreFlight)
pushd spineml_2_brahms
./package.sh ${S2B_VER} ${DISTRO} ${S2B_BR}
sudo cp /var/cache/pbuilder/${DISTRO}-amd64-result/spineml-2-brahms_${S2B_VER}-1_amd64.deb \
    /var/cache/pbuilder/localdeps/
sudo cp /var/cache/pbuilder/${DISTRO}-i386-result/spineml-2-brahms_${S2B_VER}-1_i386.deb \
    /var/cache/pbuilder/localdeps/
popd

# Build SpineCreator
pushd spinecreator
./package.sh ${SC_VER} ${DISTRO} ${SC_BR}
sudo cp /var/cache/pbuilder/${DISTRO}-amd64-result/spinecreator_${SC_VER}-1_amd64.deb \
    /var/cache/pbuilder/localdeps/
sudo cp /var/cache/pbuilder/${DISTRO}-i386-result/spinecreator_${SC_VER}-1_i386.deb \
    /var/cache/pbuilder/localdeps/
popd

# Last thing, make a copy of the packages.
mkdir -p build_${DISTRO}_201501-1
cp /var/cache/pbuilder/localdeps/*.deb build_${DISTRO}_201501-1/
