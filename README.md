# mzNES

A lightweight, educational Nintendo Entertainment System (NES) emulator written in **Zig** + **SDL3**.  
The source code is licensed under the MIT license.  

  
Project started: `Sep.1.2026`  
Project finished: 

[![Zig Version](https://img.shields.io/badge/Zig-0.17.0-orange.svg)](https://ziglang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

`zmNES` is a low-level NES emulator built from scratch to explore Zig's capabilities.

## Status & Features

- [x] **iNES Format Parsing**: Header validation, Mapper ID extraction, PRG/CHR ROM loading.
- [x] **Memory Management**: Zero-leak guarantee via explicit allocators & `errdefer` semantics.
- [ ] **CPU Core (Ricoh 2A03)**: MOS 6502 instruction decoding, address modes, and interrupt handling.
- [ ] **PPU (Picture Processing Unit)**: Background rendering, OAM sprite rendering, and NMI logic.
- [ ] **APU (Audio Processing Unit)**: Pulse, Triangle, Noise, and DMC channel synthesis.
- [ ] **Mappers**:
  - [ ] Mapper 0 (NROM)
  - [ ] Mapper 1 (MMC1)
  - [ ] Mapper 3 (CNROM)
