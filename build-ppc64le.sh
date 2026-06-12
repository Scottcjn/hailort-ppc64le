#!/bin/bash
# Build script for HailoRT on ppc64le
# Elyan Labs 2025-2026
#
# IMPORTANT: Hailo-8 support lives on the `hailo8` branch (HailoRT 4.23.0,
# the terminal Hailo-8 line). Upstream `master` is Hailo-10/15-ONLY and
# will not drive a Hailo-8. Do not build master for this card.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HAILO_BRANCH="hailo8"   # HailoRT 4.23.0 — the Hailo-8 line

echo "=== HailoRT ppc64le Build Script (branch: $HAILO_BRANCH) ==="
echo ""

# Check architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "ppc64le" && "$ARCH" != "ppc64" ]]; then
    echo "WARNING: This build is intended for ppc64le, but detected: $ARCH"
    echo "Proceeding anyway for cross-compilation testing..."
fi

# Clone repos if not present — MUST be the hailo8 branch
if [ ! -d "$SCRIPT_DIR/hailort" ]; then
    echo "Cloning HailoRT SDK ($HAILO_BRANCH branch)..."
    git clone -b "$HAILO_BRANCH" https://github.com/hailo-ai/hailort.git "$SCRIPT_DIR/hailort"
fi

if [ ! -d "$SCRIPT_DIR/hailort-drivers" ]; then
    echo "Cloning HailoRT drivers ($HAILO_BRANCH branch)..."
    git clone -b "$HAILO_BRANCH" https://github.com/hailo-ai/hailort-drivers.git "$SCRIPT_DIR/hailort-drivers"
fi

# Guard against a stale master checkout (master = Hailo-10/15-only)
for repo in hailort hailort-drivers; do
    branch=$(git -C "$SCRIPT_DIR/$repo" rev-parse --abbrev-ref HEAD)
    if [ "$branch" != "$HAILO_BRANCH" ]; then
        echo "ERROR: $repo is on '$branch', not '$HAILO_BRANCH'."
        echo "       master does not support Hailo-8. Re-clone with:"
        echo "       rm -rf $SCRIPT_DIR/$repo && $0"
        exit 1
    fi
done

# Apply patches (both apply from the hailort repo root)
echo ""
echo "=== Applying patches ==="

cd "$SCRIPT_DIR/hailort"
for p in 01-tokenizers-ppc64le.patch 02-python-ppc64le-platform.patch; do
    if git apply --check "$SCRIPT_DIR/patches/$p" 2>/dev/null; then
        git apply "$SCRIPT_DIR/patches/$p"
        echo "Applied: $p"
    else
        echo "Patch $p already applied or conflicts detected"
    fi
done

echo ""
echo "=== Patches applied ==="
echo ""
echo "Next steps:"
echo "1. Build + install kernel driver (against the running kernel):"
echo "   cd hailort-drivers/linux/pcie && make all && sudo make install"
echo ""
echo "2. Install device firmware (4.23.0, fetched by upstream script):"
echo "   cd hailort-drivers && ./download_firmware.sh"
echo "   sudo mkdir -p /lib/firmware/hailo"
echo "   sudo cp hailo8_fw.4.23.0.bin /lib/firmware/hailo/hailo8_fw.bin"
echo "   sudo cp linux/pcie/51-hailo-udev.rules /etc/udev/rules.d/"
echo "   sudo udevadm control --reload && sudo modprobe hailo_pci"
echo ""
echo "3. Build HailoRT library:"
echo "   cd hailort/hailort && mkdir build && cd build"
echo "   cmake .. -DCMAKE_BUILD_TYPE=Release"
echo "   make -j32   # 32 threads is the POWER8 compile sweet spot"
echo ""
echo "4. Verify the card:  hailortcli scan && hailortcli fw-control identify"
echo ""
echo "POWER8 DMA NOTE: watch 'dmesg -w' during the first scan/inference."
echo "The driver requests a 64-bit DMA mask, which on PowerNV/PHB3 maps the"
echo "TCE bypass window at 1<<59. If the card's vDMA engine can't drive those"
echo "high address bits you'll see transfers fail or an 'EEH: Frozen PHB'"
echo "event. Mitigations, in order:"
echo "  a) boot with iommu=nobypass (forces translated DMA), or"
echo "  b) patch linux/vdma/vdma.c to start at DMA_BIT_MASK(48) on ppc64le."
