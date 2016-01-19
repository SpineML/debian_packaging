#!/bin/bash

# Update script for an interation of an existing package. The
# upstream source is expected to have changed in this case.

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

Update Debian package of ${PROGRAM_NAME} with given srcversion, which is
expected to be a full upstream update.

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
GIT_BRANCH_REQUEST="master"
if [ ! -z $4 ]; then
    GIT_BRANCH_REQUEST="$4"
fi

VERSION="$1"
PREVDEBVERSION="$2"
# As we're packaging a new upstream release, here's the new deb
# package version string.
NEWDEBVERSION=${VERSION}-1 # FIXME: Perhaps have option of -1ubuntu1 style prefix?
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
    --distribution ${DISTRO} --urgency low -v $NEWDEBVERSION
if [ "$?" -ne 0 ]; then bailout "debchange"; fi

DEBHELPER_COMPAT_LEVEL=9
echo ${DEBHELPER_COMPAT_LEVEL} > debian/compat

. ../scripts/debian_control

. ../scripts/debian_lintian_overrides

. ../scripts/debian_copyright

. ../scripts/debian_rules

# The source readme needs to be updated
cat > debian/README.source <<EOF
${PROGRAM_NAME} for Debian
-----------------------

This package was produced from a source tarball built from the git repository
at ${GIT_ACCCOUNT}/${GIT_REPO_DIR}

The git commit revision is: ${GIT_LAST_COMMIT_SHA} of ${GIT_LAST_COMMIT_DATE} on
the ${GIT_BRANCH} branch.
EOF


popd

echo "build_package..."
. ../build_package
