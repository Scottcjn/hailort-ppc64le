# HailoRT ppc64le Port

[![BCOS Certified](https://img.shields.io/badge/BCOS-Certified-brightgreen?style=flat&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0id2hpdGUiPjxwYXRoIGQ9Ik0xMiAxTDMgNXY2YzAgNS41NSAzLjg0IDEwLjc0IDkgMTIgNS4xNi0xLjI2IDktNi40NSA5LTEyVjVsLTktNHptLTIgMTZsLTQtNCA1LjQxLTUuNDEgMS40MSAxLjQxTDEwIDE0bDYtNiAxLjQxIDEuNDFMMTAgMTd6Ii8+PC9zdmc+)](BCOS.md)
Port of Hailo-8 SDK (HailoRT) to IBM POWER8/POWER9 PowerPC 64-bit Little Endian architecture.

## Overview

This repository contains patches and build instructions for running Hailo-8 (26 TOPS)
AI accelerator on ppc64le systems like IBM POWER8 S824.

> **⚠️ Branch matters:** Hailo-8 support lives on upstream's **`hailo8` branch
> (HailoRT 4.23.0, the terminal Hailo-8 line)**. Upstream `master` is
> **Hailo-10/15-only** and will not drive a Hailo-8. Everything here —
> patches, build script, instructions — targets the `hailo8` branch.
> (Patches rebased and verified against it 2026-06-12.)

## Status

| Component | Status | Notes |
|-----------|--------|-------|
| Kernel Driver | Ready | Uses standard ioread32/iowrite32 (endian-safe) |
| HailoRT Library | Patched | tokenizers.cmake and setup.py |
| Python Bindings | Patched | Platform list updated |
| Rust Tokenizers | Patched | Cargo target added |

## Patches

- `01-tokenizers-ppc64le.patch` - Adds ppc64le/ppc64 Rust cargo targets
- `02-python-ppc64le-platform.patch` - Adds ppc64le to Python wheel platforms

## Requirements

### POWER8/POWER9 System
- Ubuntu 20.04+ or RHEL 8+ on ppc64le
- Kernel headers for driver compilation
- CMake 3.14+
- GCC 8+
- Rust/Cargo (for tokenizers)

### Hailo-8 Hardware
- Hailo-8 M.2 or PCIe card
- PCIe slot with sufficient power

## Building

### Apply Patches

```bash
git clone -b hailo8 https://github.com/hailo-ai/hailort.git
git clone -b hailo8 https://github.com/hailo-ai/hailort-drivers.git
cd hailort
git apply ../patches/01-tokenizers-ppc64le.patch
git apply ../patches/02-python-ppc64le-platform.patch
```

Or just run `./build-ppc64le.sh`, which clones the correct branches,
refuses to proceed on a `master` checkout, and applies both patches.

### Build Kernel Driver

```bash
cd hailort-drivers/linux/pcie
make all
sudo make install
```

### Build HailoRT Library

```bash
cd hailort/hailort
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
sudo make install
```

### Build Python Bindings

```bash
cd hailort/hailort/libhailort/bindings/python/platform
pip install -e .
```

## Architecture Notes

### Endianness

The Hailo-8 is a PCIe device. The kernel driver uses Linux's `ioread32`/`iowrite32`
functions which are endian-safe for PCIe MMIO access. No endianness patches required
for the driver.

### SIMD

The userspace library's quantization code only uses x86 SIMD on Windows (MSVC).
On Linux, it uses portable `rintf()`. No SIMD patches required.

### Tokenizers

The tokenizers-cpp library uses Rust. We add the `powerpc64le-unknown-linux-gnu`
target to cmake configuration.

## Target Hardware (validation pending)

- IBM Power System S824 (POWER8), Ubuntu 20.04 ppc64le, kernel 5.4
- Hailo-8 26 TOPS M.2 accelerator via passive M.2-to-PCIe-x4 adapter

Patches are verified to apply cleanly against the `hailo8` branch; the
kernel-5.4 window is inside the driver's compat range (2.6.22-6.13).
First `hailortcli fw-control identify` on the S824 is still pending —
this section becomes "Tested" when it succeeds, with benchmark numbers.

### POWER8 DMA / IOMMU — the expected runtime risk

The driver requests a 64-bit DMA mask first (`linux/vdma/vdma.c`), which on
PowerNV/PHB3 maps the TCE **bypass window at `1<<59`**. Consumer-class
endpoints sometimes can't drive those high address bits even though they
claim a 64-bit mask — symptoms are silent transfer failures or an
`EEH: Frozen PHB` event in dmesg. Mitigations, in order:

1. Try stock first; watch `dmesg -w` during `hailortcli scan`.
2. Boot with `iommu=nobypass` to force translated DMA through the TCE window.
3. One-line driver patch: start at `DMA_BIT_MASK(48)` on ppc64le in
   `vdma.c` — if needed, that patch is this port's upstream-worthy
   contribution.

If the card doesn't enumerate at boot, the
[oculink-gpu-bypass](https://github.com/Scottcjn/oculink-gpu-bypass)
PCIe rescan script is the fallback.

## Model Pipeline (compile on x86, run on POWER)

The Hailo Dataflow Compiler is **x86_64-only** — but you rarely need it:
the model zoo's Hailo-8 line (v2.x) publishes **pre-compiled HEFs**
(YOLOv8/v10/v11, classification, segmentation, pose, depth; Whisper
tiny/base via hailo-whisper). Compile custom models on any x86 box and
copy the `.hef` over; HEFs are opaque blobs with no host-arch dependency.
Match zoo-2.x HEFs to HailoRT 4.2x (the `hailo8` branch) — 5.x-zoo HEFs
are the Hailo-10/15 line.

## Credits

- Hailo Technologies Ltd - Original HailoRT SDK
- Scott Boudreaux / Elyan Labs - ppc64le port

## License

HailoRT is MIT licensed. Patches in this repository are also MIT licensed.

## References

- [HailoRT GitHub](https://github.com/hailo-ai/hailort)
- [Hailo Driver GitHub](https://github.com/hailo-ai/hailort-drivers)
- [Hailo Documentation](https://hailo.ai/developer-zone/)

---

### Part of the Elyan Labs Ecosystem

- [BoTTube](https://bottube.ai) — AI video platform where 119+ agents create content
- [RustChain](https://rustchain.org) — Proof-of-Antiquity blockchain with hardware attestation
- [GitHub](https://github.com/Scottcjn)
