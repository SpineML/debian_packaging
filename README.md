debian_packaging
================

Packaging files for Debian or Ubuntu releases

This is a set of scripts which will create Debian packages of the
software which is required to run SpineCreator successfully.

These are, at present:

SpineCreator itself, which is a user interface allowing the creation
of a SpineML neural network model.

BRAHMS - one possible simulation backend which can be used to execute
the components of the SpineML neural network model (as well as many
other systems).

SpineML-2-BRAHMS - Some scripts which take the SpineML output of
SpineCreator and generate and compile C++ code which forms the
components which BRAHMS executes.

SpineML_PreFlight - Code to pre-parse a SpineML model so that it is
ready for SpineML_2_BRAHMS or any other simulation backend.

These scripts have been developed on Seb's laptop and are currently
Seb-specific, meaning that if you want to run them, you'll have to
review them to change from using Seb's signing keys to your own as
well as other changes that I can't think of at the moment.

The scripts should checkout the SpineCreator, brahms,
SpineML_PreFlight and SpineML_2_BRAHMS source code into src/
subdirectories

Now cd into debian_packaging/brahms and run the
package.sh script.  You'll have to install a number of Debian
developer packages, including pbuilder. Here are the packaging dependencies:

 sudo apt-get install build-essential autoconf automake autotools-dev
                      dh-make debhelper devscripts fakeroot xutils
                      lintian pbuilder cdbs

Actually, some of these may not be strictly necessary on the host
system. I believe debhelper only needs to be installed within the
chroot in which pbuilder compiles the code.

Review the script first as it isn't going to work first time!

Packaging Debian on an Ubuntu system:

Creating the base.tgz is the trick. First, add the Debian keyring:

sudo apt-get install debian-archive-keyring

Then, be sure to add this to the pbuilder create call:

--debootstrapopts "--keyring=/usr/share/keyrings/debian-archive-keyring.gpg"

So it might be:

sudo pbuilder --create --architecture amd64 --distribution jessie \
 --basetgz /var/cache/pbuilder/jessie-amd64-base.tgz \
 --debootstrapopts "--keyring=/usr/share/keyrings/debian-archive-keyring.gpg"
