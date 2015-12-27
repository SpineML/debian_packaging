debian_packaging
================

Packaging files for Debian releases

This is a set of scripts which will create Debian packages of the software
which is required to run SpineCreator successfully.

These are, at present:

SpineCreator itself, which is a user interface allowing the creation of
a SpineML neural network model.

BRAHMS - one possible simulation backend which can be used to execute
the components of the SpineML neural network model (as well as many other
systems).

SpineML-2-BRAHMS - Some scripts which take the SpineML output of SpineCreator
and generate and compile C++ code which forms the components which BRAHMS
executes.

These scripts have been developed on Seb's laptop and are currently Seb-specific,
meaning that if you want to run them, you'll have to review them to change from
using Seb's signing keys to your own as well as other changes that I can't think
of at the moment.

The scripts are intended to run from:

~/src/debian_packaging

with the SpineCreator, brahms, SpineML_PreFlight and SpineML_2_BRAHMS
git repos checked out in:

~/src/

That is - checkout everything in ~/src.

Now cd into ~/greenbrain/debian_packaging/brahms and run the package.sh script.
You'll have to install a number of Debian developer packages, including pbuilder.

Review the script first as it isn't going to work first time!
