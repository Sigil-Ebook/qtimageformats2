#!/bin/bash -e

# WARNING!!  Do not attempt to run this script outside of a docker container. Doing so can damage your system!!

# This script is for building the sigil appimage
# Please run this script in docker image: ubuntu:22.04
# E.g: docker run --rm -v `git rev-parse --show-toplevel`:/reporoot ubuntu:22.04 /reporoot/.github/workflows/build_qtplugins.sh
# Artifacts will copy to the same directory.

set -o pipefail

export PY_SHORT_VER="3.14"
export PYTHON_VER="3.14.2"
export QT6_VER="6.10"
export QT6_VER_FULL="6.10.2"
export QT6_FN="6102"
export LC_ALL="C.UTF-8"
export DEBIAN_FRONTEND=noninteractive
export PKG_CONFIG_PATH=/usr/local/lib64/pkgconfig
SELF_DIR="$(readlink -f "$(dirname "$0")")"

retry() {
  # max retry 5 times
  try=5
  # sleep 30 sec every retry
  sleep_time=15
  for i in $(seq ${try}); do
    echo "executing with retry: $@" >&2
    if eval "$@"; then
      return 0
    else
      echo "execute '$@' failed, tries: ${i}" >&2
      sleep ${sleep_time}
    fi
  done
  echo "execute '$@' failed" >&2
  return 1
}


prepare_baseenv() {
  rm -f /etc/apt/sources.list.d/*.list*

  # keep debs in container for store cache in docker volume
  rm -f /etc/apt/apt.conf.d/*
  echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/01keep-debs
  echo -e 'Acquire::https::Verify-Peer "false";\nAcquire::https::Verify-Host "false";' > /etc/apt/apt.conf.d/99-trust-https

  # Since cmake 3.23.0 CMAKE_INSTALL_LIBDIR will force set to lib/<multiarch-tuple> on Debian
  echo '/usr/local/lib/x86_64-linux-gnu' > /etc/ld.so.conf.d/x86_64-linux-gnu-local.conf
  echo '/usr/local/lib64' > /etc/ld.so.conf.d/lib64-local.conf
  retry apt-get update

  retry apt-get install -y --allow-downgrades software-properties-common apt-transport-https
  retry apt-get update

  retry apt-get install -y \
    make \
    build-essential \
    curl \
    wget \
    file \
    zip \
    p7zip-full \
    zstd \

  apt-get autoremove --purge -y
  # strip all compiled files by default
  export CFLAGS='-s'
  export CXXFLAGS='-s'
  # Force refresh ld.so.cache
  ldconfig
}


prepare_buildenv() {
  # Install Cmake
  if ! which cmake &>/dev/null; then
    cmake_latest_ver="$(retry curl -ksSL --compressed https://cmake.org/download/ \| grep "'Latest Release'" \| sed -r "'s/.*Latest Release\s*\((.+)\).*/\1/'" \| head -1)"
    cmake_binary_url="https://github.com/Kitware/CMake/releases/download/v${cmake_latest_ver}/cmake-${cmake_latest_ver}-linux-x86_64.tar.gz"
    cmake_sha256_url="https://github.com/Kitware/CMake/releases/download/v${cmake_latest_ver}/cmake-${cmake_latest_ver}-SHA-256.txt"
    if [ -f "/usr/src/cmake-${cmake_latest_ver}-linux-x86_64.tar.gz" ]; then
      cd /usr/src
      cmake_sha256="$(retry curl -ksSL --compressed "${cmake_sha256_url}" \| grep "cmake-${cmake_latest_ver}-linux-x86_64.tar.gz")"
      if ! echo "${cmake_sha256}" | sha256sum -c; then
        rm -f "/usr/src/cmake-${cmake_latest_ver}-linux-x86_64.tar.gz"
      fi
    fi
    if [ ! -f "/usr/src/cmake-${cmake_latest_ver}-linux-x86_64.tar.gz" ]; then
      retry curl -kLo "/usr/src/cmake-${cmake_latest_ver}-linux-x86_64.tar.gz" "${cmake_binary_url}"
    fi
    tar -zxf "/usr/src/cmake-${cmake_latest_ver}-linux-x86_64.tar.gz" -C /usr/local --strip-components 1
  fi
  cmake --version

  # Install Ninja
  if ! which ninja &>/dev/null; then
    ninja_ver="$(retry curl -ksSL --compressed https://ninja-build.org/ \| grep "'The last Ninja release is'" \| sed -r "'s@.*<b>(.+)</b>.*@\1@'" \| head -1)"
    ninja_binary_url="https://github.com/ninja-build/ninja/releases/download/${ninja_ver}/ninja-linux.zip"
    if [ ! -f "/usr/src/ninja-${ninja_ver}-linux.zip.download_ok" ]; then
      rm -f "/usr/src/ninja-${ninja_ver}-linux.zip"
      retry curl -kLC- -o "/usr/src/ninja-${ninja_ver}-linux.zip" "${ninja_binary_url}"
      touch "/usr/src/ninja-${ninja_ver}-linux.zip.download_ok"
    fi
    unzip -d /usr/local/bin "/usr/src/ninja-${ninja_ver}-linux.zip"
  fi
  echo "Ninja version $(ninja --version)"
}


setup_python() {
  mkdir -p /opt/sigiltools
  python_url="https://github.com/dougmassay/win-qtwebkit-5.212/releases/download/v5.212-1/sigilpython${PYTHON_VER}.tar.xz"
  if [ -f "/reporoot/sigilpython${PYTHON_VER}.tar.xz" ]; then
    echo "Using local Python archive"
    tar -xJf "/reporoot/sigilpython${PYTHON_VER}.tar.xz" -C /opt/sigiltools
  else
    if [ ! -f "/usr/src/sigilpython${PYTHON_VER}.tar.xz.download_ok" ]; then
      rm -f "/usr/src/sigilpython${PYTHON_VER}.tar.xz"
      retry curl -kLC- -o "/usr/src/sigilpython${PYTHON_VER}.tar.xz" "${python_url}"
      touch "/usr/src/sigilpython${PYTHON_VER}.tar.xz.download_ok"
    fi
    tar -xJf "/usr/src/sigilpython${PYTHON_VER}.tar.xz" -C /opt/sigiltools
  fi
  export PATH=/opt/sigiltools/python/bin:$PATH
  export LD_LIBRARY_PATH=/opt/sigiltools/python/lib:$LD_LIBRARY_PATH
  export PYTHONHOME=/opt/sigiltools/python
  which python3
  echo "Upgrading pip..."
  export PIP_ROOT_USER_ACTION=ignore
  python3 -m ensurepip
  python3 -m pip install --upgrade --force-reinstall --root-user-action ignore pip --disable-pip-version-check --no-warn-script-location
  echo "Python version $(python3 --version)"
}


setup_qt6() {
  python3 -m pip install --root-user-action ignore aqtinstall
  python3 -m aqt install-qt --outputdir /opt/sigiltools/Qt linux desktop "${QT6_VER_FULL}" linux_gcc_64 --archives qtbase
  export PATH=/opt/sigiltools/Qt/$QT6_VER_FULL/gcc_64/bin:$PATH
  export LD_LIBRARY_PATH=/opt/sigiltools/Qt/${QT6_VER_FULL}/gcc_64/lib:$LD_LIBRARY_PATH
  export Qt6_Dir="/opt/sigiltools/Qt/${QT6_VER_FULL}/gcc_64/lib/cmake/Qt6"
  export Qt6_DIR="/opt/sigiltools/Qt/${QT6_VER_FULL}/gcc_64/lib/cmake/Qt6"
  export QT_PLUGIN_PATH="/opt/sigiltools/Qt/${QT6_VER_FULL}/gcc_64/plugins"
  echo "Qt version $(qmake -v)"
}

build_plugins() {
  mkdir -p /build
  cd build
  cmake /reporoot \
    -G "Ninja" \
    -DCMAKE_PREFIX_PATH="/opt/sigiltools/Qt/${QT6_VER_FULL}/gcc_64/lib/cmake" \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCONFIG_PIC=1 \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_IGNORE_PREFIX_PATH=/usr \
    -DCMAKE_IGNORE_PREFIX_PATH=/usr/local \
    -DAVIF_CODEC_AOM=SYSTEM \
    -DAVIF_LIBYUV=SYSTEM
  ninja -j$(getconf _NPROCESSORS_ONLN)
  cp -fv lib/libqavif.so /reporoot/libqavif.so
  cp -fv lib/libqjpegxl6.so /reporoot/libqjpegxl6.so
}

time {
  prepare_baseenv
  prepare_buildenv
  setup_python
  setup_qt6
  build_plugins
}