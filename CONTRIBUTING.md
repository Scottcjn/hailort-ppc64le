# Contributing

Thanks for helping maintain the HailoRT ppc64le port. This repository tracks
patches and build notes for Hailo-8 on IBM POWER systems, so contributions
should be precise about architecture, hardware, and validation.

## Getting Started

1. Read `README.md` for current component status, requirements, and build steps.
2. Review patches in `patches/` before changing platform or tokenizer support.
3. Work on a focused branch:

   ```bash
   git checkout -b your-change-name
   ```

## Development Workflow

Keep changes scoped to one area:

- `build-ppc64le.sh` for build automation.
- `patches/` for HailoRT, tokenizers, or Python platform fixes.
- `README.md` for setup, hardware, and architecture notes.
- `BCOS.md` for certification context.

Avoid mixing patch updates with unrelated documentation rewrites. If a patch
changes, include how it applies against upstream HailoRT or driver sources.

## Validation

For patch changes, include:

```bash
git apply --check patches/*.patch
```

For full hardware validation, include:

- POWER8/POWER9 system model and OS.
- Kernel, GCC/CMake, Rust/Cargo, and Python versions.
- HailoRT source version or commit.
- Hailo-8 device type and connection.
- Build commands and any runtime checks performed.

If hardware was not available, state that clearly and include static validation
or source-level review instead.

## Code and Patch Style

- Keep ppc64le platform additions minimal and upstream-friendly.
- Preserve upstream license headers and context in patch files.
- Be explicit about endian assumptions around PCIe MMIO and userspace code.
- Document why a platform entry or build flag is required.

## Pull Request Checklist

Before opening a PR, include:

- Summary of the driver, library, Python, or tokenizer area affected.
- Patch application status and build/test commands.
- Hardware and OS used, or a clear note that hardware testing was unavailable.
- Known limitations and upstream references.

