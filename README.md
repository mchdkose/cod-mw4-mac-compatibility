# COD: MW4 Mac Compatibility

Compatibility and performance improvements for running COD: MW4 on macOS with CrossOver.

**Version 1 — Stable release**

## Improvements

- Startup compatibility and improved initialization handling
- Performance, GPU timing and exception compatibility improvements
- Shader compatibility improvements
- Audio fixes
- Cache and connectivity preparation
- Ultra texture download and local streaming

## Installation

1. Download and extract the ZIP from **Releases**.
2. Copy `MW4-Compatibility.exe`, `sp26.dylib` and the whole `MW4-Ultra-Textures` folder into the game's `sp26` folder. Replace the previous program files when updating.
3. In your CrossOver bottle, use **Run Command** to open `MW4-Compatibility.exe`.

Use this EXE for future launches. You can save it as a CrossOver launcher. Keep both program files together. No launch arguments or separate setup are needed for the compatibility fix.

When updating an existing texture folder, copy the new files into it and keep its `Data` folder. Stop the game and textures before updating.

## Ultra textures

1. On your Mac, open `MW4-Ultra-Textures/Ultra-Textures.command`.
2. Approve the displayed download size and storage location to download or resume.
3. After verification, open the same command and choose **Start Textures**, then launch the game through CrossOver as usual.
4. Keep the texture window open while playing. After exiting the game, press **Control-C** in that window to stop textures and restore routing.

Textures require **Python 3.10+** and a large separate download. The size and available space are shown before downloading; an external drive can be selected. Starting textures asks for macOS administrator permission. No game assets are included in the ZIP. See the included texture README for details and recovery options.

## Recommended setup

> **Required CrossOver version:** you have to download this version of CrossOver: **`crossover-preview-20261015.zip`**.
> ⚠️ **Do NOT use the ARM64 build.** Download the standard (non-ARM64) `crossover-preview-20261015.zip`.

- CrossOver Preview (`crossover-preview-20261015.zip`, **not the ARM64 build**) with D3DMetal 4.0b3.
- Select **D3DMetal** as the graphics backend for your game bottle.
- Enable **Metal 4** and **MSync** in CrossOver for your game bottle (recommended).

## Tested configuration

**M4 Max / macOS 27 / CrossOver Preview 27.0.0.41073 / D3DMetal 4.0b3**

This is the tested configuration, not a minimum hardware or exact-version requirement. Other configurations have not yet been verified.

## Project status

Our first stable release, with further compatibility and performance improvements planned.

The first game window can still take a while to appear. If a waiting window appears, startup continues while it is open. **Keep waiting** dismisses the window; **Cancel launch** stops that launch.

## Reporting an issue

Open an issue with your Mac model, macOS version, CrossOver version and a description of the problem. Include the error message or a screenshot when available.
