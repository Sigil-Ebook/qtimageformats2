###A#####################################################
#  
#  This is a CMake configuration file.
#  To use it you need CMake which can be 
#  downloaded from here: 
#    http://www.cmake.org/cmake/resources/software.html
#
#########################################################

cmake_minimum_required(VERSION 3.20)
project(qtimageformats C CXX)

# Ensure all sub-projects output binaries to the same central directories
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# force some global defines
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Forced OFF" FORCE)    
set(CMAKE_POSITION_INDEPENDENT_CODE ON CACHE BOOL "Forced ON" FORCE)    

        
# ==============================================================================
# 1. ORCHESTRATE LIBYUV (Scaling & Pixel Conversions)
# ==============================================================================
# libyuv doesn't use complex cache flags, but ensure it registers its targets

add_subdirectory(3rdparty/libyuv)

# ==============================================================================
# 2. ORCHESTRATE AOM (AV1 Codec)
# ==============================================================================
# first override Find

set(LIBYUV_FOUND ON CACHE BOOL "Forced ON" FORCE)
set(LIBYUV_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/libyuv/include CACHE STRINGS "Force" FORCE)
set(LIBYUV_LIBRARIES ${CMAKE_BINARY_DIR}/lib CACHE STRING "Force" FORCE)
set(LIBYUV_LIBRARY ${CMAKE_BINARY_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}yuv${CMAKE_STATIC_LIBRARY_SUFFIX} CACHE STRING "Force" FORCE)
 
# Disable heavy testing frameworks and command-line tools to speed up compilation
set(CONFIG_PIC ON CACHE BOOL "Forced On" FORCE) 
set(ENABLE_TESTS OFF CACHE BOOL "Forced OFF" FORCE)
set(ENABLE_TEST_DATA OFF CACHE BOOL "Forced OFF" FORCE)
set(ENABLE_EXAMPLES OFF CACHE BOOL "Forced OFF" FORCE)
set(ENABLE_TOOLS OFF CACHE BOOL "Forced OFF" FORCE)
set(ENABLE_DOCS OFF CACHE BOOL "Forced OFF" FORCE)

add_subdirectory(3rdparty/aom)

# ==============================================================================
# 3. ORCHESTRATE LIBAVIF (AVIF Container Format)
# ==============================================================================
# first override Find
set(AOM_FOUND ON CACHE BOOL "Forced ON" FORCE)
set(AOM_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/aom CACHE STRING "Force" FORCE)
set(AOM_LIBRARIES ${CMAKE_BINARY_DIR}/lib CACHE STRING "Force" FORCE)
set(AOM_LIBRARY ${CMAKE_BINARY_DIR}/lib//${CMAKE_STATIC_LIBRARY_PREFIX}aom${CMAKE_STATIC_LIBRARY_SUFFIX} CACHE STRING "Force" FORCE)

# Force libavif to look INSIDE this build directory instead of find_package()
set(AVIF_CODEC_AOM ON CACHE BOOL "Forced ON to use internal libaom" FORCE)

add_subdirectory(3rdparty/libavif)

# ==============================================================================
# 4. ORCHESTRATE LIBJXL (JPEG XL Codec)
# ==============================================================================
# Block libjxl from building its internal third-party duplicates
set(JPEGXL_BUNDLE_SKCMS ON CACHE BOOL "Forced ON" FORCE)
set(JPEGXL_ENABLE_BENCHMARK OFF CACHE BOOL "Forced OFF" FORCE)
set(JPEGXL_ENABLE_EXAMPLES OFF CACHE BOOL "Forced OFF" FORCE)
set(JPEGXL_ENABLE_MANPAGES OFF CACHE BOOL "Forced OFF" FORCE)
set(JPEGXL_ENABLE_TOOLS OFF CACHE BOOL "Forced OFF" FORCE)
set(JPEGXL_ENABLE_DOXYGEN OFF CACHE BOOL "Forced OFF" FORCE)
set(JPEGXL_ENABLE_SJPEG OFF CACHE BOOL "Forced OFF" FORCE)
set(JPEGXL_WARNINGS_AS_ERRORS OFF CACHE BOOL "Forced OFF" FORCE)       
set(BUILD_TESTING OFF CACHE BOOL "Forced OFF" FORCE)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DJXL_STATIC_DEFINE -DJXL_THREADS_STATIC_DEFINE -DJXL_CMS_STATIC_DEFINE")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DJXL_STATIC_DEFINE -DJXL_THREADS_STATIC_DEFINE -DJXL_CMS_STATIC_DEFINE")

add_subdirectory( 3rdparty/libjxl)

add_subdirectory( src )

