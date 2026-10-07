// SPDX-FileCopyrightText: 2026 David Holbert
// SPDX-License-Identifier: GPL-3.0-or-later

// Live system output peak level for the audio-reactive idle glow.
// Backend: PulseAudioQt VolumeMonitor pointed at a sink object (the same
// KDE/PipeWire/PulseAudio stack as SystemVolume) — a real monitor-stream
// peak, not an estimate from playback state, and not shell polling.
//
// The monitor pushes peak updates on its own (~26 Hz while audio flows),
// so no polling of audio state is needed; a 50 ms envelope timer only
// advances the smoothing math. Fast attack, slow release: responsive
// without twitchiness, no beat detection, no flashing.
import QtQuick
import org.kde.plasma.private.volume as PAVolume

QtObject {
    id: root

    // Input: sink VolumeObject to monitor (bind to SystemVolume.activeSink).
    // Null-safe: with no sink the level simply decays to 0.
    property var sink: null

    // Envelope rates per pushed update (applied on each volumeChanged).
    property real attack: 0.35
    property real release: 0.08

    property var _monitor: PAVolume.VolumeMonitor {
        target: root.sink
    }

    // Raw 0..1 peak straight from the monitor stream. A null sink forces
    // 0 (the monitor retains its last value with no target, so without
    // this the glow would freeze instead of dimming).
    readonly property real peak: {
        if (root.sink === null || root.sink === undefined) {
            return 0;
        }
        const v = _monitor.volume;
        if (typeof v !== "number" || !(v > 0)) {
            return 0;
        }
        return Math.min(1, v);
    }

    // Smoothed level consumed by the glow. Rises fast, falls slowly.
    // Stepped by a cheap 50ms envelope timer (plain arithmetic on the
    // cached peak, no I/O) rather than only on peak-change events, so the
    // glow reliably decays to faint during silence instead of freezing at
    // the last pushed value when the monitor goes quiet.
    property real level: 0
    property var _envelope: Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: {
            const p = root.peak;
            root.level = root.level + (p - root.level) * (p > root.level ? root.attack : root.release);
        }
    }
}
