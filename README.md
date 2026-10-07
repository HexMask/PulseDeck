# PulseDeck

Compact hardware-inspired media controls for Plasma with MPRIS transport, system volume, customizable accent lighting, and audio-reactive pulse.

## Features

- **MPRIS Transport** — Previous / Play-Pause / Next
- **Optional Seek** — Seek Back / Seek Forward (configurable interval)
- **System Volume** — Controls the actual output volume (PipeWire/PulseAudio), works with any player (Brave, Firefox, VLC, Spotify, etc.)
- **Horizontal & Vertical Panels** — Proper layout for both orientations
- **Customizable Accent Color** — Pick any color for the accent lighting
- **Audio-Reactive Pulse** — The button outline and symbol pulse with the live system audio level
- **Hover/Pressed Overrides** — Hover and pressed states always take priority over the audio pulse

## Requirements

- KDE Plasma 6
- Qt 6
- PipeWire/PulseAudio (for system volume and audio monitoring)

## Installation

```bash
kpackagetool6 -t Plasma/Applet -i io.github.HexMask.PulseDeck
```

Or install the `.plasmoid` file directly via Plasma's widget installer.

## Configuration

Right-click the widget → Configure to access:

- **Accent color** — The color used for outlines, symbols, and pulse (default: `#0ee841`)
- **Show seek buttons** — Enable optional Seek Back/Forward buttons
- **Seek interval** — Seconds to jump per seek press (default: 10)
- **Audio-reactive glow** — Enable/disable the audio-reactive pulse (default: on)
- **Automatic player selection** — Follow the currently playing MPRIS player (default: on)
- **Manual player** — Lock to a specific MPRIS identity when automatic is off

## Controls

| Control | Action |
|---------|--------|
| Click Previous | Previous track |
| Click Play/Pause | Toggle playback |
| Click Next | Next track |
| Click Seek Back | Seek backward (configurable interval) |
| Click Seek Forward | Seek forward (configurable interval) |
| Drag/click volume fader | Adjust system output volume |
| Mouse wheel anywhere | Adjust system output volume |
| Keyboard volume keys | Adjust system output volume (synced) |

## Audio-Reactive Pulse

When enabled, the button outline and symbol pulse in sync with the live system audio level:

- Silence/quiet → dim (~30% intensity)
- Medium levels → clearly visible (~60%)
- Strong peaks → full bright (100%)
- Hover/pressed states override the pulse instantly
- Paused or disabled → static approved idle appearance

## License

GPL-3.0-or-later

Copyright 2026 David Holbert

SPDX-License-Identifier: GPL-3.0-or-later
SPDX-FileCopyrightText: 2026 David Holbert