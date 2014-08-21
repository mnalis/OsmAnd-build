#!/bin/bash

if [ -z "$BASH_VERSION" ]; then
	echo "Invalid shell, re-running using bash..."
	exec bash "$0" "$@"
	exit $?
fi
SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Verify environment
if [[ -z "$OSMAND_TARGET" ]]; then
	echo "Building for target '${OSMAND_TARGET}'"
	OSMAND_TARGET_SPECIFICATION="-DOSMAND_TARGET=${OSMAND_TARGET}"
	if [[ -f "$SRCLOC/../target/${OSMAND_TARGET}.sh" ]]; then
		source "$SRCLOC/../target/${OSMAND_TARGET}.sh"
	fi
elif [[ -z "$OSMAND_CROSSPLATFORM_TARGET" ]]; then
	echo "Building for cross-platform target '${OSMAND_TARGET}'"
	OSMAND_TARGET_SPECIFICATION="-DCMAKE_TOOLCHAIN_FILE=targets/${OSMAND_CROSSPLATFORM_TARGET}.cmake"
else
	echo "OSMAND_TARGET and OSMAND_CROSSPLATFORM_TARGET is not set - one of them needs to be set"
	exit 1
fi 

# Configure build type
CMAKE_BUILD_TYPE=""
BUILD_TYPE_SUFFIX=""
if [ -n "$1" ]
then
	case "$1" in
		debug)		CMAKE_BUILD_TYPE="Debug"
					BUILD_TYPE_SUFFIX="debug"
					;;
		release)	CMAKE_BUILD_TYPE="Release"
					BUILD_TYPE_SUFFIX="release"
					;;
		safemode)	CMAKE_BUILD_TYPE="RelWithDebInfo"
					BUILD_TYPE_SUFFIX="safemode"
					;;
	esac
fi
if [ -n "$CMAKE_BUILD_TYPE" ]
then
	echo "Building in $CMAKE_BUILD_TYPE mode"
	CMAKE_BUILD_TYPE="-DCMAKE_BUILD_TYPE:STRING=$CMAKE_BUILD_TYPE"
	BUILD_TYPE_SUFFIX="-$BUILD_TYPE_SUFFIX"
fi

# Specific CPU configuration
OSMAND_CPU_SPECIFIC_DEFINE=""
CPU_SPECIFIC_SUFFIX=""
if [ -n "$OSMAND_SPECIFIC_CPU_NAME" ]; then
	echo "Building for CPU : $OSMAND_SPECIFIC_CPU_NAME"
	OSMAND_CPU_SPECIFIC_DEFINE="-DCMAKE_SPECIFIC_CPU_NAME:STRING=$OSMAND_SPECIFIC_CPU_NAME"
	CPU_SPECIFIC_SUFFIX="-$OSMAND_SPECIFIC_CPU_NAME"
fi

# Get target prefix
TARGET_PREFIX=""
if [ -n "$OSMAND_TARGET_PREFIX" ]; then
	TARGET_PREFIX="$OSMAND_TARGET_PREFIX-"
fi

# Check for specific compiler selected
SPECIFIC_CC_COMPILER=""
if [[ -n "$OSMAND_CC" ]]; then
	SPECIFIC_CC_COMPILER="CC=${OSMAND_CC}"
fi
SPECIFIC_CXX_COMPILER=""
if [[ -n "$OSMAND_CXX" ]]; then
	SPECIFIC_CXX_COMPILER="CXX=${OSMAND_CXX}"
fi

WORK_ROOT="$SRCLOC/.."
BAKED_DIR="$SRCLOC/../../baked/$TARGET_PREFIX$OSMAND_TARGET$CPU_SPECIFIC_SUFFIX$BUILD_TYPE_SUFFIX.$TARGET_BUILD_TOOL_SUFFIX"
echo "Baking project files in $BAKED_DIR"
if [[ -d "$BAKED_DIR" ]]; then
	rm -rf "$BAKED_DIR"
fi
mkdir -p "$BAKED_DIR"
(cd "$BAKED_DIR" && \
	$SPECIFIC_CC_COMPILER $SPECIFIC_CXX_COMPILER cmake -G "$CMAKE_GENERATOR" \
		-DCMAKE_TARGET_BUILD_TOOL:STRING=$TARGET_BUILD_TOOL_SUFFIX \
		$OSMAND_TARGET_TOOLCHAIN \
		$CMAKE_BUILD_TYPE \
		$OSMAND_CPU_SPECIFIC_DEFINE \
		"$WORK_ROOT")