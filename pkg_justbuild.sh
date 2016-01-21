#!/bin/bash

# Build script to build an existing source package.

# a "bailout error message" function. Allows me to write error tests like:
# if [ "$?" -ne 0 ]; then bailout "some message"; fi
. ../bailout

# Source the program name and GIT_REPO_DIR
. ./scripts/program_name

function usage () {
   cat <<EOF

usage: $0 srcversion pkgversion distro

Build Debian package of ${PROGRAM_NAME} with given srcversion,
pkgversion and for distro.

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
DEBVERSION="$2"
DISTRO="$3"

# The deb source directory will be created with this directory name
DEBNAME=${PROGRAM_NAME}-${VERSION}

# The "orig" tarball will have this name
DEBORIG=${PROGRAM_NAME}_${VERSION}.orig

rm -rf ${DEBNAME}

tar xvf ${DEBORIG}.tar.gz
if [ "$?" -ne 0 ]; then bailout "unpacking deborig (of prev version)"; fi

pushd ${DEBNAME}

# Unpack previous package version debian directory
tar xvf ../${PROGRAM_NAME}_${DEBVERSION}.debian.tar.[gx]z
if [ "$?" -ne 0 ]; then bailout "unpacking debian.tar.gz (of prev version)"; fi

NEWDEBVERSION=${DEBVERSION}

popd

echo "build_package..."
. ../build_package
