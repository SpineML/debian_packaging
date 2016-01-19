To add a new quilt managed patch:

We're using dquilt, an alias for:

 quilt --quiltrc=/home/seb/.quiltrc-dpkg

First, apply existing patches. This is done within the $DEBNAME dir - so
in brahms-0.8.0 which is created by pkg-update.sh or similar:

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

Now there is a debian/patches directory. What will happen to it when I re-run
pkg_update.sh? They'll get removed, so copy debian/patches to debian_patches

cp -Ra debian/patches ../debian_patches

pkg_update.sh will copy these in when it updates the package from the old
.orig.tar.gz and .debian.tar.[gx]z files.


OLD:
After you've popped, you can then run

 dpkg-buildpackage -rfakeroot

To test the changes.

I save the contents of debian/patches to ../brahms-0.7.3.debian_patches
as the build script will start completely from scratch each time.
