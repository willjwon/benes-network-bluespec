#!/bin/zsh
set -e

# Get absolute path of where this script is located at
SCRIPT_DIR=$(dirname "$(realpath $0)")
BUILD_DIR=${SCRIPT_DIR}/build
BIN_DIR=${BUILD_DIR}/bin
B_DIR=${BUILD_DIR}/bdir
INFO_DIR=${BUILD_DIR}/info
SIM_DIR=${BUILD_DIR}/sim

# cleanup
function removeBuildDir {
    rm -rf ${BUILD_DIR}
}

function createBuildDirs {
    mkdir -p ${BUILD_DIR}
    mkdir -p ${B_DIR}
    mkdir -p ${INFO_DIR}
    mkdir -p ${BIN_DIR}
    mkdir -p ${SIM_DIR}
}

INCLUDE_PATH="+"  # default: current folder
function compute_include_path {
    for directory in $(find $SCRIPT_DIR -mindepth 1 -type d); do
		if ! [[ ${directory} =~ ${SCRIPT_DIR}/[.].* || ${directory} =~ ${BUILD_DIR}.* ]]; then
            # excludes folders starting with dot (e.g., .git), or build directory
			INCLUDE_PATH="${INCLUDE_PATH}:${directory}"
		fi
    done
}

function compileSimulation {
    # compile bsv files
    bsc -u -sim \
        -aggressive-conditions -check-assert -parallel-sim-link 8 \
        -bdir ${B_DIR} -simdir ${SIM_DIR} -info-dir ${INFO_DIR} \
        -p ${INCLUDE_PATH} \
        ./testbench/$1.bsv

    # copmile bluesim (simulation) binary
    bsc -u -sim \
        -e mk$1 -o ${BIN_DIR}/$1 \
        -parallel-sim-link 8 \
        -bdir ${B_DIR} -simdir ${SIM_DIR} -info-dir ${INFO_DIR} \
        -Xc++ -O0
}

function runSimulation {
    ${BIN_DIR}/$1
}


# main run script
# Script
case "$1" in
-l|--clean)
    removeBuildDir;;
-c|--compile)
    removeBuildDir
    compute_include_path
    createBuildDirs
    compileSimulation $2;;
-r|--run)
    runSimulation $2;;
-h|--help|*)
    printf "TODO";;
esac
