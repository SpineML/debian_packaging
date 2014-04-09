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
