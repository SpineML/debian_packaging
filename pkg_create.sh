#!/bin/bash

# Create script for a brand new package.

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

usage: $0 version distro <branch>

Branch defaults to 'master' if omitted.

Create Debian package of ${PROGRAM_NAME} with given version.

EOF
}

# Set the correct umask
umask 0022
# Avoid any gcc that's installed in /usr/local/bin
export PATH=/usr/bin:/bin

# The package maintainer parameters.
. ../package_maintainer

# Get version, distro, git branch from the command line
if [ -z $2 ]; then
    usage
    exit 1
fi
GIT_BRANCH_REQUEST="master"
if [ ! -z $3 ]; then
    GIT_BRANCH_REQUEST="$3"
fi

VERSION="$1"
NEWDEBVERSION="$1"-1
DISTRO="$2"

# Source the Intention To Package bug number
. ./scripts/itpbug

# The deb source directory will be created with this directory name
DEBNAME=${PROGRAM_NAME}-${VERSION}

# The "orig" tarball will have this name
DEBORIG=${PROGRAM_NAME}_${VERSION}.orig

# Clean up any previously generated tarballs and files
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}.debian.tar.gz
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}.dsc
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_amd64.changes
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_amd64.deb
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_amd64.build
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_i386.changes
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_i386.deb
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_i386.build
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_source.changes

# Unpack deborig
rm -rf ${DEBNAME}
tar xvf ${DEBORIG}.tar.gz
if [ "$?" -ne 0 ]; then bailout "unpacking deborig"; fi

pushd ${DEBNAME}

# Run dh_make.
dh_make -s
if [ "$?" -ne 0 ]; then bailout "dh_make"; fi

# We should have no upstream bugs to fix, as we ARE the upstream
# maintainers.  However, the dquilt stuff would normally go here.

# Remove example files created by dh_make
rm -rf debian/*.ex
rm -rf debian/*.EX

# We don't need a README.Debian file to describe special instructions
# about running this softare on Debian.
rm -f debian/README.Debian

# Create the fresh debian/changelog.
rm -f debian/changelog
debchange --create --package ${PROGRAM_NAME} --closes ${ITPBUG} \
    --distribution ${DISTRO} --urgency low --newversion ${NEWDEBVERSION}
if [ "$?" -ne 0 ]; then bailout "debchange"; fi

DEBHELPER_COMPAT_LEVEL=9
echo ${DEBHELPER_COMPAT_LEVEL} > debian/compat

if [ -f ../scripts/debian_docs ]; then
    . ../scripts/debian_docs
fi

. ../scripts/debian_control

. ../scripts/debian_lintian_overrides

. ../scripts/debian_copyright

. ../scripts/debian_rules

# The source readme is copied in from a file created by pkg_curatesrc.sh
cp ../debian_README.source debian/README.source
if [ "$?" -ne 0 ]; then bailout "failed to copy in debian_README.source"; fi

popd

echo "build_package..."
. ../build_package
