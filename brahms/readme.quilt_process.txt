To add a new quilt managed patch:

We're using dquilt, an alias for:

 quilt --quiltrc=/home/seb/.quiltrc-dpkg

First, apply existing patches:

 dquilt push -a

Create a new patch

 dquilt new my-new-patch

Add file(s):

 dquilt add somefile

NOW make changes to somefile (and any others you added).

After changes, refresh:

 dquilt refresh

When finished, remove all patches, ready for the next build:

 dquilt pop -a

After you've popped, you can then run

 dpkg-buildpackage -rfakeroot

To test the changes.

I save the contents of debian/patches to ../brahms-0.7.3.debian_patches
as the build script will start completely from scratch each time.
