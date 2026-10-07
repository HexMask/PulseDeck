// SPDX-FileCopyrightText: 2026 David Holbert
// SPDX-License-Identifier: GPL-3.0-or-later

// MPRIS transport selection + logic (Previous / Play-Pause / Next / Seek).
// Visual skin lives in ../components. Volume is intentionally NOT handled
// here: volume is system output volume (see SystemVolume.qml), so it works
// like the desktop volume keys regardless of the active player.
// Generic MPRIS only: no per-application (Brave/Firefox/VLC/...) special cases.
import QtQuick
import org.kde.plasma.private.mpris as Mpris

QtObject {
    id: root

    // Bound from plasmoid.configuration by main.qml
    property bool automatic: true
    property string manualIdentity: ""

    // Last identity observed in Playing state (for "most recently active").
    property string lastActiveIdentity: ""
    property bool _selecting: false

    property var mprisModel: Mpris.Mpris2Model {
        id: mprisModel

        readonly property int containerRole: Qt.UserRole + 1

        function playerAt(i) {
            if (i < 0 || i >= rowCount()) {
                return null;
            }
            return data(index(i, 0), containerRole);
        }

        function findIndexByIdentity(identity) {
            if (!identity || identity.length === 0) {
                return -1;
            }
            for (let i = 0; i < rowCount(); i++) {
                const p = playerAt(i);
                if (p && p.identity === identity) {
                    return i;
                }
            }
            return -1;
        }

        function findPlayingIndex() {
            for (let i = 0; i < rowCount(); i++) {
                const p = playerAt(i);
                if (p && p.playbackStatus === Mpris.PlaybackStatus.Playing) {
                    return i;
                }
            }
            return -1;
        }

        function applySelection() {
            if (root._selecting) {
                return;
            }
            root._selecting = true;
            try {
                if (!root.automatic) {
                    // Manual override: lock to the configured identity.
                    const wanted = (root.manualIdentity || "").trim();
                    if (wanted.length === 0) {
                        return;
                    }
                    const idx = findIndexByIdentity(wanted);
                    if (idx >= 0 && currentIndex !== idx) {
                        currentIndex = idx;
                    }
                    return;
                }
                // Automatic: 1. prefer currently Playing.
                const playing = findPlayingIndex();
                if (playing >= 0) {
                    const pp = playerAt(playing);
                    if (pp && pp.identity) {
                        root.lastActiveIdentity = pp.identity;
                    }
                    if (currentIndex !== playing) {
                        currentIndex = playing;
                    }
                    return;
                }
                // 2. otherwise prefer most recently active if still present.
                if (root.lastActiveIdentity.length > 0) {
                    const recent = findIndexByIdentity(root.lastActiveIdentity);
                    if (recent >= 0) {
                        if (currentIndex !== recent) {
                            currentIndex = recent;
                        }
                        return;
                    }
                }
                // 3. keep current index if valid, else fall back to first row.
                if (rowCount() > 0 && (currentIndex < 0 || currentIndex >= rowCount())) {
                    currentIndex = 0;
                }
            } finally {
                root._selecting = false;
            }
        }

        function trackPlayingIdentity() {
            const playing = findPlayingIndex();
            if (playing >= 0) {
                const p = playerAt(playing);
                if (p && p.identity && p.identity !== root.lastActiveIdentity) {
                    root.lastActiveIdentity = p.identity;
                }
            }
        }

        onRowsInserted: applySelection()
        onRowsAboutToBeRemoved: applySelection()
        onRowsRemoved: applySelection()
        onDataChanged: {
            trackPlayingIdentity();
            applySelection();
        }
        onCurrentPlayerChanged: trackPlayingIdentity()

        Component.onCompleted: applySelection()
    }

    // Re-evaluate automatic selection periodically so a newly-Playing
    // player is followed even if a model signal was missed.
    property var _pollTimer: Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: {
            if (root.automatic) {
                mprisModel.trackPlayingIdentity();
                mprisModel.applySelection();
            }
        }
    }

    onAutomaticChanged: mprisModel.applySelection()
    onManualIdentityChanged: {
        if (!root.automatic) {
            mprisModel.applySelection();
        }
    }

    // -- Selected player -------------------------------------------------
    readonly property var player: {
        if (!root.automatic && (root.manualIdentity || "").trim().length > 0) {
            const idx = mprisModel.findIndexByIdentity((root.manualIdentity || "").trim());
            if (idx < 0) {
                return null;
            }
            return mprisModel.playerAt(idx);
        }
        return mprisModel.currentPlayer;
    }

    readonly property bool hasPlayer: player !== null && player !== undefined
    readonly property int playerCount: mprisModel.rowCount()

    function playerIdentities() {
        const out = [];
        for (let i = 0; i < mprisModel.rowCount(); i++) {
            const p = mprisModel.playerAt(i);
            if (p && p.identity) {
                out.push(p.identity);
            }
        }
        return out;
    }

    // -- Metadata ---------------------------------------------------------
    readonly property string identity: hasPlayer ? (player.identity || "") : ""
    readonly property string track: hasPlayer ? (player.track || "") : ""
    readonly property string artist: hasPlayer ? (player.artist || "") : ""
    readonly property string album: hasPlayer ? (player.album || "") : ""
    readonly property string artUrl: hasPlayer ? (player.artUrl || "") : ""
    readonly property int playbackStatus: hasPlayer ? player.playbackStatus : Mpris.PlaybackStatus.Stopped
    readonly property bool playing: playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property double position: hasPlayer ? player.position : 0
    readonly property double length: hasPlayer ? player.length : 0

    // -- Capabilities ------------------------------------------------------
    readonly property bool canControl: hasPlayer ? !!player.canControl : false
    readonly property bool canGoNext: hasPlayer ? !!player.canGoNext : false
    readonly property bool canGoPrevious: hasPlayer ? !!player.canGoPrevious : false
    readonly property bool canPlay: hasPlayer ? !!player.canPlay : false
    readonly property bool canPause: hasPlayer ? !!player.canPause : false
    readonly property bool canSeek: hasPlayer ? !!player.canSeek : false

    readonly property bool canTogglePlay: hasPlayer && (canPlay || canPause || playing)

    // -- Actions ------------------------------------------------------------
    function togglePlay() {
        if (hasPlayer && canTogglePlay) {
            player.PlayPause();
        }
    }

    function next() {
        if (hasPlayer && canGoNext) {
            player.Next();
        }
    }

    function previous() {
        if (hasPlayer && canGoPrevious) {
            player.Previous();
        }
    }

    // MPRIS Seek takes a microsecond offset relative to the current position.
    function seekBy(offsetSeconds) {
        if (hasPlayer && canSeek) {
            player.Seek(Math.round(offsetSeconds * 1000000));
        }
    }
}
