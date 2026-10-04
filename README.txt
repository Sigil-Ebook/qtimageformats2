Repo: qtimageformats2

The Epub3.4 spec now allows for jpegxl (jx) and avif image formats
to be base media types that do not require fallbacks.

Unfortunately Qt6 does not support these formats either at the qtbase module
level or the qtimageformats level.

Sigil needs to add support via qt6 image plugins for Windows, MacOS, and
Linux.  This repo has been set up to allow easy automated builds
for inclusion in our own versions of Qt6.10.2 we ship with Sigil on
Windows, MacOS, and as an AppImage for Linux.

This repo merges the following 6 code repositories:
    https://github.com/aomediacodec/libavif
    https://github.com/lemenkov/libyuv
    https://github.com/mozilla/aom
    https://github.com/libjxl/libjxl (and all its dependencies)
    https://github.com/novomesk/qt-avif-image-plugin
    https://github.com/novomesk/qt-jpegxl-image-plugin

and then tries to simplify things as much as possible to reduce duplication,
so that a single cmake command will build qt-avif-image-plugin and
qt-jpegxl-image-plugin statically linked to their dependencies.
The build is designed to work on Linux, MacOS and Windows.

Note tha the warious subprojects have had their CMakeLists.txt files modified
to make things work together so diff each 3rdparty lib against the current
contents to see the CMakeLists.txt changes needed if trying to use newer versions.
The qmake .pro files in the two plugins have also been converted to CMakeLists.txt
files.

No install is done, everything stays local to the build directory

The current way to build this on Linux is with the following
cmake commands:

cmake -G "Unix Makefiles" -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release
      -DCONFIG_PIC=1 -DCMAKE_POSITION_INDEPENDENT_CODE=ON
      -DCMAKE_IGNORE_PREFIX_PATH=/usr
      -DCMAKE_IGNORE_PREFIX_PATH=/usr/local
      -DAVIF_CODEC_AOM=SYSTEM
      -DAVIF_LIBYUV=SYSTEM ../qtimageformats2

or alternative the build works with Ninja instead of Unix Makefiles as well.

Notice the -DCMAKE_IGNORE_PREFIX are set to exclude /usr/lib and /usr/local/lib
to force pure static versions of all libraries and not shared versions
based on existing libjxl, libaom, libyuv, and libavif since these are
meant for standalone qt6 image plugin.

Also note, there are a huge number of warnings when building libjxl and its
sub libraries.  These were not introduced by us at all.

For MacOS: - first make sure the Qt bin directory can be found

export PATH=${PATH}:/Users/kbhend/Qt6102/bin

cmake -G "Unix Makefiles" -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release
    -DCONFIG_PIC=1 -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DCMAKE_IGNORE_PREFIX_PATH=/opt/local -DCMAKE_IGNORE_PREFIX_PATH=/usr/local
    -DAVIF_CODEC_AOM=SYSTEM -DAVIF_LIBYUV=SYSTEM ../qtimageformats2

Notice the -DCMAKE_IGNORE_PREFIX_PATH=/opt/local and -DCMAKE_IGNORE_PREFIX_PATH=/usr/local
which are used to turn off where any non-MacOS libs might have been installed

For Windows:  add in perl and use Ninja as the target following keep the pertinent
defines from the Linux make command.

