#!/bin/bash

# Update script for a an interation of an existing package. The
# upstream source must not change in this case.

# What's our pwd? This is important, as we're going to run this in
# subdirectories.
pwd

# a "bailout error message" function. Allows me to write error tests like:
# if [ "$?" -ne 0 ]; then bailout "some message"; fi
. ../bailout

# Source the program name and GIT_REPO_DIR
. ./scripts/program_name

function usage () {
   cat <<EOF

usage: $0 srcversion prevpkgversion distro <branch>

Branch defaults to 'master' if omitted.

Update Debian package of ${PROGRAM_NAME} with given version.

EOF
}

# Set the correct umask
umask 0022
# Avoid any gcc that's installed in /usr/local/bin
export PATH=/usr/bin:/bin

# The package maintainer parameters.
. ../package_maintainer

# Get version, distro, git branch from the command line
if [ -z $3 ]; then
    usage
    exit 1
fi

VERSION="$1"
PREVDEBVERSION="$2"
DISTRO="$3"

# Source the Intention To Package bug number
. ./scripts/itpbug

# The deb source directory will be created with this directory name
DEBNAME=${PROGRAM_NAME}-${VERSION}

# The "orig" tarball will have this name
DEBORIG=${PROGRAM_NAME}_${VERSION}.orig

rm -rf ${DEBNAME}

tar xvf ${DEBORIG}.tar.gz
if [ "$?" -ne 0 ]; then bailout "unpacking deborig (of prev version)"; fi

pushd ${DEBNAME}

# Unpack previous package version debian directory
tar xvf ../${PROGRAM_NAME}_${PREVDEBVERSION}.debian.tar.[gx]z
if [ "$?" -ne 0 ]; then bailout "unpacking debian.tar.gz (of prev version)"; fi

debchange --package ${PROGRAM_NAME} \
    --distribution ${DISTRO} --urgency low --increment
if [ "$?" -ne 0 ]; then bailout "debchange"; fi

# Obtain the new debian version from the changelog:
NEWDEBVERSION=`head -n1 debian/changelog | awk -F '[(]' '{ print \$2; }'| awk -F '[)]' '{ print \$1; }'`

# Add any patches here. How to manage this process?
# copy in patches, so that they add to any patches already existing in the debian.tar.gz:
if [ -d ../debian_patches ]; then
    mkdir -p debian/patches
    cp -Ra ../debian_patches/* debian/patches/
fi

DEBHELPER_COMPAT_LEVEL=9
echo ${DEBHELPER_COMPAT_LEVEL} > debian/compat

. ../scripts/debian_control

. ../scripts/debian_lintian_overrides

. ../scripts/debian_copyright

. ../scripts/debian_menu

. ../scripts/debian_rules

# The source readme normally remains the same, but it'll do no harm to
# copy it in again, in case we wanted to add anything.
cp ../debian_README.source debian/README.source
if [ "$?" -ne 0 ]; then bailout "failed to copy in debian_README.source"; fi

popd

echo "build_package..."
. ../build_package
