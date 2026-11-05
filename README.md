# RG34XX RetroArch shader presets

These presets use a lightweight CRT shader tuned for the RG34XX's 320x480
portrait display. Select a preset from RetroArch's **Shaders** menu.

| System | Preset |
| --- | --- |
| NES / Famicom | `rg34xx_nes.glslp` |
| SNES / Super Famicom | `rg34xx_snes.glslp` |
| Game Boy Advance (Granular LCD) | `rg34xx_gba_granular.glslp` with `rg34xx_gba_granular.glsl` |
| Game Boy | `rg34xx_gb.glslp` |
| Game Boy Color | `rg34xx_gbc.glslp` |
| PC Engine / TurboGrafx-16 | `rg34xx_pc_engine.glslp` |
| PC Engine CD / TurboGrafx-CD | `rg34xx_pc_engine_cd.glslp` |

Keep `rg34xx_crt.glsl` and every preset in the same RetroArch shaders
directory. Apply a preset for the content's core; the system presets are
also compatible with their standalone core aliases.

## Installation

From the Knulli device, run:

```sh
curl -fsSL https://raw.githubusercontent.com/yuleshow/rg34xx-knulli-shaders/main/install.sh | sh
```

The installer automatically uses an existing RetroArch shader directory. To
choose an explicit location:

```sh
curl -fsSL https://raw.githubusercontent.com/yuleshow/rg34xx-knulli-shaders/main/install.sh | sh -s -- --dir /Volumes/share
```
