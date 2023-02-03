#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors



################################################################################
# Build
################################################################################

echo "BEGIN MESSAGE"
echo "Building pciutils..."
echo "END MESSAGE"

# Set locations
THORN=pciutils
NAME=pciutils-3.2.0
SRCDIR="$(dirname $0)"
BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
if [ -z "${PCIUTILS_INSTALL_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "pciutils install directory, PCIUTILS_INSTALL_DIR, not set. Installing in the default configuration location. "
    echo "END MESSAGE"
    INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
else
    echo "BEGIN MESSAGE"
    echo "pciutils install directory, PCIUTILS_INSTALL_DIR, selected. Installing pciutils at ${PCIUTILS_INSTALL_DIR} "
    echo "END MESSAGE"
    INSTALL_DIR=${PCIUTILS_INSTALL_DIR}
fi
PCIUTILS_DIR=${INSTALL_DIR}

(
    if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
        set -x                  # Output commands
    fi
    set -e                      # Abort on errors
    cd ${SCRATCH_BUILD}
    if [ -e ${DONE_FILE} -a ${DONE_FILE} -nt ${SRCDIR}/dist/${NAME}.tar.gz \
                         -a ${DONE_FILE} -nt ${SRCDIR}/configure.sh ]
    then
        echo "BEGIN MESSAGE"
        echo "pciutils: The enclosed pciutils library has already been built; doing nothing"
        echo "END MESSAGE"
    else
        echo "BEGIN MESSAGE"
        echo "pciutils: Building enclosed pciutils library"
        echo "END MESSAGE"
        
        if [ x$TAR = x ] ; then
          echo 'BEGIN ERROR'
          echo 'Could not find tar command. Please make sure that (gnu) tar is present'
          echo 'and that the TAR variable is set to its location.'
          echo 'END ERROR'
          exit 1
        fi
        if [ x$PATCH = x ] ; then
          echo 'BEGIN ERROR'
          echo 'Could not find patch command. Please make sure that (gnu) tar is present'
          echo 'and that the PATCH variable is set to its location.'
          echo 'END ERROR'
          exit 1
        fi

        export LDFLAGS="${CFLAGS} ${LDFLAGS}"
        export LDLIBS="-lz"
        unset LIBS
        if echo '' ${ARFLAGS} | grep 64 > /dev/null 2>&1; then
            export OBJECT_MODE=64
        fi
        
        echo "BEGIN MESSAGE"
        echo "pciutils: Preparing directory structure..."
        echo "END MESSAGE"
        mkdir build external done 2> /dev/null || true
        rm -rf ${BUILD_DIR} ${INSTALL_DIR}
        mkdir ${BUILD_DIR} ${INSTALL_DIR}
        
        echo "BEGIN MESSAGE"
        echo "pciutils: Unpacking archive..."
        echo "END MESSAGE"
        pushd >/dev/null ${BUILD_DIR}
        ${TAR?} xzf ${SRCDIR}/dist/${NAME}.tar.gz
        
        echo "BEGIN MESSAGE"
        echo "pciutils: Configuring..."
        echo "END MESSAGE"
        cd ${NAME}
        # pciutils does not have a configure script; doing nothing
        
        echo "BEGIN MESSAGE"
        echo "pciutils: Building..."
        ${MAKE} PREFIX="${PCIUTILS_DIR}" CC="${CC}" CFLAGS="${CFLAGS}" OPT= LDFLAGS="${LDFLAGS}" LDLIBS="${LDLIBS}" AR="${AR}" RANLIB="${RANLIB}" ZLIB=yes DNS=no SHARED=no
        echo "END MESSAGE"
        
        echo "BEGIN MESSAGE"
        echo "pciutils: Installing..."
        ${MAKE} PREFIX=${PCIUTILS_DIR} install install-lib
        popd >/dev/null
        echo "END MESSAGE"
        
        echo "BEGIN MESSAGE"
        echo "pciutils: Cleaning up..."
        echo "END MESSAGE"
        rm -rf ${BUILD_DIR}
        
        date > ${DONE_FILE}
        echo "BEGIN MESSAGE"
        echo "pciutils: Done."
        echo "END MESSAGE"
    fi
)

if (( $? )); then
    echo 'BEGIN ERROR'
    echo 'Error while building pciutils. Aborting.'
    echo 'END ERROR'
    exit 1
fi



#PCIUTILS_INC_DIRS="${PCIUTILS_DIR}/include"
#PCIUTILS_LIB_DIRS="${PCIUTILS_DIR}/lib"
#PCIUTILS_LIBS='pci'

export PKG_CONFIG_PATH=${PCIUTILS_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}

inc_dirs="$(pkg-config libpci --cflags)"
lib_dirs="$(pkg-config libpci --libs)"
libs="$(pkg-config libpci --libs)"
# Translate option flags into Cactus options:
# - for INC_DIRS, remove -I prefix from flags
# - for LIB_DIRS, remove all -l flags, and remove -L prefix from flags
# - for LIBS, keep only -l flags, and remove -l prefix from flags
PCIUTILS_INC_DIRS="$(echo '' $(for flag in $inc_dirs; do echo '' $flag; done | sed -e 's/^ -I//'))"
PCIUTILS_LIB_DIRS="$(echo '' $(for flag in $lib_dirs; do echo '' $flag; done | grep -v '^ -l' | sed -e 's/^ -L//'))"
PCIUTILS_LIBS="$(echo '' $(for flag in $libs; do echo '' $flag; done | grep '^ -l' | sed -e 's/^ -l//'))"



################################################################################
# Configure Cactus
################################################################################

PCIUTILS_INC_DIRS="$(${CCTK_HOME}/lib/sbin/strip-incdirs.sh ${PCIUTILS_INC_DIRS})"
PCIUTILS_LIB_DIRS="$(${CCTK_HOME}/lib/sbin/strip-libdirs.sh ${PCIUTILS_LIB_DIRS})"

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "PCIUTILS_DIR      = ${PCIUTILS_DIR}"
echo "PCIUTILS_INC_DIRS = ${PCIUTILS_INC_DIRS}"
echo "PCIUTILS_LIB_DIRS = ${PCIUTILS_LIB_DIRS}"
echo "PCIUTILS_LIBS     = ${PCIUTILS_LIBS}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(PCIUTILS_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(PCIUTILS_LIB_DIRS)'
echo 'LIBRARY           $(PCIUTILS_LIBS)'
