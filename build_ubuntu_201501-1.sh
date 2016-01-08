#!/bin/bash

# Builds all 4 packages for an Ubuntu Distro. Just pass in the distro
# name (e.g. trusty)

# Check MIRRORSITE is correct
ms=`egrep ^MIRRORSITE /etc/pbuilderrc|grep ubuntu.com/ubuntu`
if [ x"$ms" = "x" ]; then
    echo "Set MIRRORSITE=http://gb.archive.ubuntu.com/ubuntu/ in /etc/pbuilderrc"
    exit
fi

if [ -z "$1" ]; then
    echo "Pass in distro tag (trusty or wily etc)"
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
