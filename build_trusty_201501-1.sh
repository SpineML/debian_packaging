#!/bin/bash

# Builds all 4 packages for Trusty Tahir (Ubuntu 2014.4)

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
DISTRO=trusty

BRAHMS_VER=0.8.0
BRAHMS_BR=master
BRAHMS_ITPBUG=742518 # Not yet passed into package.sh

S2B_VER=1.0.0
S2B_BR=master
S2B_ITPBUG=742517 # Not yet passed in

SPF_VER=0.1.0
SPF_BR=master
SPF_ITPBUG=9999 # Not real

SC_VER=0.9.5
SC_BR=master
SC_ITPBUG=9999 # Not real

mkdir build_trusty_201501-1

# Build BRAHMS
pushd brahms
./package.sh ${BRAHMS_VER} ${DISTRO} master
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

# Build SpineML_2_BRAHMS (which depends on BRAHMS)
pushd spineml_2_brahms
./package.sh ${S2B_VER} ${DISTRO} master
sudo cp /var/cache/pbuilder/${DISTRO}-amd64-result/spineml-2-brahms_${S2B_VER}-1_amd64.deb \
    /var/cache/pbuilder/localdeps/
sudo cp /var/cache/pbuilder/${DISTRO}-i386-result/spineml-2-brahms_${S2B_VER}-1_i386.deb \
    /var/cache/pbuilder/localdeps/
popd

# Build SpineML_PreFlight
pushd spineml_preflight
./package.sh ${SPF_VER} ${DISTRO} master
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

# Build SpineCreator
pushd spinecreator
./package.sh ${SC_VER} ${DISTRO} master
sudo cp /var/cache/pbuilder/${DISTRO}-amd64-result/spinecreator_${SC_VER}-1_amd64.deb \
    /var/cache/pbuilder/localdeps/
sudo cp /var/cache/pbuilder/${DISTRO}-i386-result/spinecreator_${SC_VER}-1_i386.deb \
    /var/cache/pbuilder/localdeps/
popd

# Last thing, make a copy of the packages.
cp /var/cache/pbuilder/localdeps/*.deb build_trusty_201501-1/
