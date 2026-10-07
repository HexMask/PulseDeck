// SPDX-FileCopyrightText: 2026 David Holbert
// SPDX-License-Identifier: GPL-3.0-or-later

// System output volume (NOT per-player MPRIS volume).
// Backend: Plasma's private.volume module (PulseAudioQt over the same
// PipeWire/Pulse-compatible stack the desktop volume keys use), so this
// behaves like the keyboard volume keys regardless of which MPRIS player
// (Brave/Firefox/VLC/Spotify/...) is active.
//
// - level is bound straight to the default sink's VolumeObject, so external
//   changes (keyboard keys, settings app, other tools) propagate instantly.
// - sink selection prefers PulseObject.default, falls back to the first
//   sink, and is re-evaluated on model changes plus a slow timer so a
//   default-output switch (e.g. headphones plugged in) is picked up.
import QtQuick
import org.kde.plasma.private.volume as PAVolume

QtObject {
    id: root

    // PulseAudio normalized volume (PA_VOLUME_NORM).
    readonly property int paNorm: 65536

    property var sinkModel: PAVolume.SinkModel {
        id: sinkModel
    }

    // One delegate per sink; exposes its VolumeObject for selection.
    property var _watcher: Instantiator {
        id: watcher
        model: sinkModel
        delegate: QtObject {
            readonly property var pulse: model.PulseObject
            onPulseChanged: root._rescan()
        }
        onObjectAdded: root._rescan()
        onObjectRemoved: root._rescan()
        onCountChanged: root._rescan()
    }

    // Slow re-scan: catches default-output switches and any missed signal.
    // Level itself stays fully event-driven (no polling of the value).
    property var _rescanTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root._rescan()
    }

    // Currently controlled sink (VolumeObject) or null.
    property var activeSink: null

    function _rescan() {
        let first = null;
        let def = null;
        for (let i = 0; i < watcher.count; i++) {
            const o = watcher.objectAt(i);
            if (!o || !o.pulse) {
                continue;
            }
            if (!first) {
                first = o.pulse;
            }
            if (o.pulse.default === true) {
                def = o.pulse;
                break;
            }
        }
        const pick = def || first;
        if (pick !== activeSink) {
            activeSink = pick;
        }
    }

    Component.onCompleted: _rescan()

    readonly property bool hasSink: activeSink !== null && activeSink !== undefined

    // 0.0 .. 1.0 system output level, straight from the sink object so
    // external changes are reflected immediately.
    readonly property real level: {
        if (!hasSink) {
            return 0;
        }
        const v = activeSink.volume;
        if (typeof v !== "number" || v < 0) {
            return 0;
        }
        return Math.max(0, Math.min(1, v / paNorm));
    }

    readonly property string sinkName: hasSink && activeSink.name ? String(activeSink.name) : ""
    readonly property string sinkDescription: hasSink && activeSink.description ? String(activeSink.description) : ""

    function setLevel(v) {
        if (!hasSink) {
            return;
        }
        const clamped = Math.max(0, Math.min(1, v));
        activeSink.volume = Math.round(clamped * paNorm);
    }

    function nudge(delta) {
        setLevel(level + delta);
    }
}
