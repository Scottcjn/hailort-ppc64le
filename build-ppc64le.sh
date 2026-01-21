#!/bin/bash
# Build script for HailoRT on ppc64le
# Elyan Labs 2025

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== HailoRT ppc64le Build Script ==="
echo ""

# Check architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "ppc64le" && "$ARCH" != "ppc64" ]]; then
    echo "WARNING: This build is intended for ppc64le, but detected: $ARCH"
    echo "Proceeding anyway for cross-compilation testing..."
fi

# Clone repos if not present
if [ ! -d "$SCRIPT_DIR/hailort" ]; then
    echo "Cloning HailoRT SDK..."
    git clone https://github.com/hailo-ai/hailort.git "$SCRIPT_DIR/hailort"
fi

if [ ! -d "$SCRIPT_DIR/hailort-drivers" ]; then
    echo "Cloning HailoRT drivers..."
    git clone https://github.com/hailo-ai/hailort-drivers.git "$SCRIPT_DIR/hailort-drivers"
fi

# Apply patches
echo ""
echo "=== Applying patches ==="

cd "$SCRIPT_DIR/hailort"
if ! git apply --check "$SCRIPT_DIR/patches/01-tokenizers-ppc64le.patch" 2>/dev/null; then
    echo "Patch 01 already applied or conflicts detected"
else
    git apply "$SCRIPT_DIR/patches/01-tokenizers-ppc64le.patch"
    echo "Applied: 01-tokenizers-ppc64le.patch"
fi

cd "$SCRIPT_DIR/hailort/hailort/libhailort/bindings/python/platform"
if ! git apply --check "$SCRIPT_DIR/patches/02-python-ppc64le-platform.patch" 2>/dev/null; then
    echo "Patch 02 already applied or conflicts detected"
else
    git apply "$SCRIPT_DIR/patches/02-python-ppc64le-platform.patch"
    echo "Applied: 02-python-ppc64le-platform.patch"
fi

echo ""
echo "=== Patches applied successfully ==="
echo ""
echo "Next steps:"
echo "1. Build kernel driver:"
echo "   cd hailort-drivers/linux/pcie && make all"
echo ""
echo "2. Build HailoRT library:"
echo "   cd hailort/hailort && mkdir build && cd build"
echo "   cmake .. -DCMAKE_BUILD_TYPE=Release"
echo "   make -j\$(nproc)"
echo ""
echo "3. Install:"
echo "   sudo make install (in both directories)"
