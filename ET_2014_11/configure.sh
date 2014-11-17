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
SRCDIR="$(dirname $0)"
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
