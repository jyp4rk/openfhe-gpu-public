#!/bin/bash
#
# Build script for OpenFHE-GPU
# Usage: ./build.sh [options]
#
# Options:
#   --clean       Clean build directory before building
#   --debug       Build in Debug mode (default: Release)
#   --jobs N      Number of parallel jobs (default: auto-detect)
#   --install     Install after building
#   --prefix PATH Installation prefix (default: /usr/local)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
BUILD_TYPE="Release"
CLEAN_BUILD=0
DO_INSTALL=0
INSTALL_PREFIX="/usr/local"
NUM_JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# CUDA architectures supported by CUDA 12.x
# Adjust based on your GPU and CUDA version
CUDA_ARCHS="70;75;80;86;89;90"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN_BUILD=1
            shift
            ;;
        --debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        --jobs)
            NUM_JOBS="$2"
            shift 2
            ;;
        --install)
            DO_INSTALL=1
            shift
            ;;
        --prefix)
            INSTALL_PREFIX="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --clean       Clean build directory before building"
            echo "  --debug       Build in Debug mode (default: Release)"
            echo "  --jobs N      Number of parallel jobs (default: $NUM_JOBS)"
            echo "  --install     Install after building"
            echo "  --prefix PATH Installation prefix (default: /usr/local)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "========================================"
echo "OpenFHE-GPU Build Script"
echo "========================================"
echo "Build type:    ${BUILD_TYPE}"
echo "Build dir:     ${BUILD_DIR}"
echo "Parallel jobs: ${NUM_JOBS}"
echo "CUDA archs:    ${CUDA_ARCHS}"
echo "========================================"

# Check for required tools
command -v cmake >/dev/null 2>&1 || { echo "Error: cmake is required but not installed."; exit 1; }
command -v nvcc >/dev/null 2>&1 || { echo "Error: nvcc (CUDA compiler) is required but not installed."; exit 1; }

# Print versions
echo ""
echo "Tool versions:"
cmake --version | head -1
nvcc --version | grep release
echo ""

# Clean build directory if requested
if [[ $CLEAN_BUILD -eq 1 ]]; then
    echo "Cleaning build directory..."
    rm -rf "${BUILD_DIR}"
fi

# Create build directory
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Run CMake configuration
echo "Configuring with CMake..."
cmake .. \
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
    -DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHS}" \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
    -Wno-dev

# Build
echo ""
echo "Building with ${NUM_JOBS} parallel jobs..."
cmake --build . --parallel "${NUM_JOBS}"

# Install if requested
if [[ $DO_INSTALL -eq 1 ]]; then
    echo ""
    echo "Installing to ${INSTALL_PREFIX}..."
    cmake --install .
fi

echo ""
echo "========================================"
echo "Build completed successfully!"
echo "========================================"
echo ""
echo "Libraries built in: ${BUILD_DIR}/lib/"
ls -la "${BUILD_DIR}/lib/"*.so* 2>/dev/null || true
echo ""
echo "Examples built in:  ${BUILD_DIR}/bin/examples/"
echo "Unit tests in:      ${BUILD_DIR}/unittest/"
echo ""
echo "To run unit tests:"
echo "  cd ${BUILD_DIR} && ./unittest/core_tests"
echo "  cd ${BUILD_DIR} && ./unittest/pke_tests"
echo "  cd ${BUILD_DIR} && ./unittest/binfhe_tests"
