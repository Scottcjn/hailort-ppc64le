# HailoRT ppc64le Port

[![BCOS Certified](https://img.shields.io/badge/BCOS-Certified-brightgreen?style=flat&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0id2hpdGUiPjxwYXRoIGQ9Ik0xMiAxTDMgNXY2YzAgNS41NSAzLjg0IDEwLjc0IDkgMTIgNS4xNi0xLjI2IDktNi40NSA5LTEyVjVsLTktNHptLTIgMTZsLTQtNCA1LjQxLTUuNDEgMS40MSAxLjQxTDEwIDE0bDYtNiAxLjQxIDEuNDFMMTAgMTd6Ii8+PC9zdmc+)](BCOS.md)
Port of Hailo-8 SDK (HailoRT) to IBM POWER8/POWER9 PowerPC 64-bit Little Endian architecture.

## Overview

This repository contains patches and build instructions for running Hailo-8 (26 TOPS)
AI accelerator on ppc64le systems like IBM POWER8 S824.

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
cd hailort
patch -p1 < ../patches/01-tokenizers-ppc64le.patch
patch -p1 < ../patches/02-python-ppc64le-platform.patch
```

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

## Tested Hardware

- IBM Power System S824 (POWER8)
- Hailo-8 26 TOPS M.2 accelerator

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
