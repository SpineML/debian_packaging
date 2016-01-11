#!/bin/bash

# Create script for a brand new package.

# What's our pwd? This is important, as we're going to run this in
# subdirectories.

pwd

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
    exit
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
DEBNAME=$PROGRAM_NAME-$VERSION

# The "orig" tarball will have this name
DEBORIG=${PROGRAM_NAME}_${VERSION}.orig

# Clean up any previously generated tarballs and files
rm -rf $DEBNAME
rm -f $DEBNAME.tar.gz
rm -f $DEBORIG.tar.gz
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}.debian.tar.gz
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}.dsc
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_amd64.changes
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_amd64.deb
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_amd64.build
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_i386.changes
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_i386.deb
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_i386.build
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_source.changes

# FIXME: Make the git checkout/update a separate script, to be called
# separately to build the .orig.tar.gz file. I get into trouble with
# launchpad otherwise.

# Our "upstream" tarball will be checked out in ./src
mkdir -p src
pushd src

if [ ! -d $DEBNAME ]; then
    if [ -d ./$GIT_REPO_DIR ]; then
        # Remove and then re-clone
        rm -rf $GIT_REPO_DIR $DEBNAME
    fi
    git clone $GIT_ACCOUNT/$GIT_REPO_DIR
    mv $GIT_REPO_DIR $DEBNAME
    pushd $DEBNAME
    git checkout -b $GIT_BRANCH_REQUEST
    git branch --set-upstream-to=origin/$GIT_BRANCH_REQUEST $GIT_BRANCH_REQUEST
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

# Run any commands that want to be done in the source code
# post-checkout. Only required for SpineCreator
. ../../scripts/post_git_checkout

popd # from $DEBNAME

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
debchange --create --package ${PROGRAM_NAME} --closes $ITPBUG \
    --distribution $DISTRO --urgency low --newversion ${NEWDEBVERSION}

DEBHELPER_COMPAT_LEVEL=9
echo $DEBHELPER_COMPAT_LEVEL > debian/compat

. ../scripts/debian_control

. ../scripts/debian_lintian_overrides

. ../scripts/debian_copyright

. ../scripts/debian_menu

. ../scripts/debian_rules

# The source readme
cat > debian/README.source <<EOF
${PROGRAM_NAME} for Debian
-----------------------

This package was produced from a source tarball built from the git repository
at ${GIT_ACCCOUNT}/${GIT_REPO_DIR}

The git commit revision is: $GIT_LAST_COMMIT_SHA of $GIT_LAST_COMMIT_DATE on
the $GIT_BRANCH branch.
EOF

popd

echo "build_package..."
. ../build_package
