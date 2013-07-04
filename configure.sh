#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
set -x                          # Output commands
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
SRCDIR=$(dirname $0)
BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
PCIUTILS_DIR=${INSTALL_DIR}

(
    exec >&2                    # Redirect stdout to stderr
    set -x                      # Output commands
    set -e                      # Abort on errors
    cd ${SCRATCH_BUILD}
    if [ -e ${DONE_FILE} -a ${DONE_FILE} -nt ${SRCDIR}/dist/${NAME}.tar.gz \
                         -a ${DONE_FILE} -nt ${SRCDIR}/configure.sh ]
    then
        echo "pciutils: The enclosed pciutils library has already been built; doing nothing"
    else
        echo "pciutils: Building enclosed pciutils library"
        
        export LDFLAGS
        unset LIBS
        if echo '' ${ARFLAGS} | grep 64 > /dev/null 2>&1; then
            export OBJECT_MODE=64
        fi
        
        echo "pciutils: Preparing directory structure..."
        mkdir build external done 2> /dev/null || true
        rm -rf ${BUILD_DIR} ${INSTALL_DIR}
        mkdir ${BUILD_DIR} ${INSTALL_DIR}
        
        echo "pciutils: Unpacking archive..."
        pushd ${BUILD_DIR}
        ${TAR?} xzf ${SRCDIR}/dist/${NAME}.tar.gz
        
        echo "pciutils: Configuring..."
        cd ${NAME}
        # pciutils does not have a configure script; doing nothing
        
        echo "pciutils: Building..."
        ${MAKE} PREFIX=${PCIUTILS_DIR} ZLIB=yes DNS=no SHARED=no
        
        echo "pciutils: Installing..."
        ${MAKE} PREFIX=${PCIUTILS_DIR} install install-lib
        popd
        
        echo "pciutils: Cleaning up..."
        rm -rf ${BUILD_DIR}
        
        date > ${DONE_FILE}
        echo "pciutils: Done."
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

PCIUTILS_INC_DIRS="$(echo '' $(pkg-config libpci --cflags) '' | sed -e 's+ -I/include + +g;s+ -I/usr/include + +g;s+ -I/usr/local/include + +g' | sed -e 's/ -I/ /g')"
PCIUTILS_LIB_DIRS="$(echo '' $(pkg-config libpci --libs) '' | sed -e 's/ -l[^ ]*/ /g' | sed -e 's+ -L/lib + +g;s+ -L/lib64 + +g;s+ -L/usr/lib + +g;s+ -L/usr/lib64 + +g;s+ -L/usr/local/lib + +g;s+ -L/usr/local/lib64 + +g' | sed -e 's/ -L/ /g')"
PCIUTILS_LIBS="$(echo '' $(pkg-config libpci --libs) '' | sed -e 's/ -[^l][^ ]*/ /g' | sed -e 's/ -l/ /g')"



################################################################################
# Configure Cactus
################################################################################

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "HAVE_PCIUTILS     = 1"
echo "PCIUTILS_DIR      = ${PCIUTILS_DIR}"
echo "PCIUTILS_INC_DIRS = ${PCIUTILS_INC_DIRS}"
echo "PCIUTILS_LIB_DIRS = ${PCIUTILS_LIB_DIRS}"
echo "PCIUTILS_LIBS     = ${PCIUTILS_LIBS}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(PCIUTILS_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(PCIUTILS_LIB_DIRS)'
echo 'LIBRARY           $(PCIUTILS_LIBS)'
