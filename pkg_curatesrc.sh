#!/bin/bash

# Create script for a brand new package.

# What's our pwd? This is important, as we're going to run this in
# subdirectories.

pwd

# Source the program name and GIT_REPO_DIR
. ./scripts/program_name

function usage () {
   cat <<EOF

usage: $0 version <branch>

Branch defaults to 'master' if omitted.

Create Debian source package of ${PROGRAM_NAME} with given version.

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
if [ ! -z $2 ]; then
    GIT_BRANCH_REQUEST="$2"
fi

VERSION="$1"
NEWDEBVERSION="$1"-1

# Source the Intention To Package bug number
. ./scripts/itpbug

# The deb source directory will be created with this directory name
DEBNAME=$PROGRAM_NAME-$VERSION

# The "orig" tarball will have this name
DEBORIG=${PROGRAM_NAME}_${VERSION}.orig

# Clean up any previously generated tarballs and files
rm -rf $DEBNAME
rm -f $DEBNAME.tar.gz

# Interactively remove deborig, as this is is an important file.
rm -i $DEBORIG.tar.gz

rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}.debian.tar.gz
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}.dsc
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_amd64.changes
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_amd64.deb
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_amd64.build
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_i386.changes
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_i386.deb
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_i386.build
rm -f ${PROGRAM_NAME}_${NEWDEBVERSION}_source.changes

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
    git checkout --track origin/$GIT_BRANCH_REQUEST
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

# Lastly, create the source package. DEBORIG is usually a copy of the
# upstream tarball. As I'm creating my upstream tarball from the git
# repo, I'll generate directly as DEBORIG.tar.gz,
tar czf $DEBORIG.tar.gz --exclude-vcs -C./src $DEBNAME

# Make the correct length of underline:
LINESTRING='--------------------------------------------------------------------------------'
NUMDASHES=$((${#PROGRAM_NAME}+11)) # 11 for " for Debian"
UNDERLINE=`echo ${LINESTRING:0:${NUMDASHES}}`

# Create the source readme, in a separate file which we'll copy in as
# debian/README.source when we call pkg_create.sh
cat > debian_README.source <<EOF
${PROGRAM_NAME} for Debian
${UNDERLINE}

This package was produced from a source tarball built from the git repository
at ${GIT_ACCOUNT}/${GIT_REPO_DIR}

The git commit revision is: ${GIT_LAST_COMMIT_SHA} of ${GIT_LAST_COMMIT_DATE} on
the ${GIT_BRANCH} branch.
EOF


echo "Source code written into $DEBORIG.tar.gz. Done."
