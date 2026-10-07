// SPDX-FileCopyrightText: 2026 David Holbert
// SPDX-License-Identifier: GPL-3.0-or-later

// PulseDeck MPRIS media controller — panel entry point.
// Layout only; MPRIS logic lives in media/MprisController.qml,
// visuals in components/*. No track text in the panel.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "media" as Media
import "components" as Synth

PlasmoidItem {
    id: root

    // The panel is the faceplate; the PulseDeck hardware draws its own body.
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Do NOT set compactRepresentation — let Plasma use the default
    // full representation (this root item). The Icon in metadata.json
    // is ONLY for the Add Widgets selector.

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property color accentColor: {
        const raw = String(Plasmoid.configuration.accentColor || "#0ee841");
        // Guard against empty/invalid config values.
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(raw) ? raw : "#0ee841";
    }
    readonly property bool showSeek: Plasmoid.configuration.showSeekButtons === true
    readonly property int seekInterval: Math.max(1, Math.min(120, parseInt(Plasmoid.configuration.seekInterval, 10) || 10))

    // Compact control sizes (artwork is 64/48 native; panels are thin).
    readonly property int transportSize: 38
    readonly property int seekSize: 30
    readonly property int volumeLength: 120

    Layout.minimumWidth: activeLayout.implicitWidth
    Layout.minimumHeight: activeLayout.implicitHeight
    Layout.preferredWidth: activeLayout.implicitWidth
    Layout.preferredHeight: activeLayout.implicitHeight

    // Exposes whichever orientation layout is currently active.
    readonly property Item activeLayout: isVertical ? verticalContent : horizontalContent

    Media.MprisController {
        id: mpris
        automatic: Plasmoid.configuration.automaticPlayer !== false
        manualIdentity: String(Plasmoid.configuration.manualPlayer || "")
    }

    // System output volume: same keys/slider behavior as the desktop
    // volume keys, independent of which MPRIS player is active.
    Media.SystemVolume {
        id: sysvol
    }

    // Live output peak driving the audio-reactive idle glow.
    Media.AudioLevel {
        id: audioMon
        sink: sysvol.activeSink
    }

    readonly property bool audioReactive: Plasmoid.configuration.audioReactiveGlow !== false

    // Wheel anywhere on the widget adjusts system output volume
    // (works with or without an active MPRIS player).
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: false
        onWheel: (wheel) => {
            sysvol.nudge(wheel.angleDelta.y > 0 ? 0.05 : -0.05);
        }
    }

    // Horizontal panel: [Seek] Prev Play Next [Seek] Volume(fader)
    RowLayout {
        id: horizontalContent
        anchors.centerIn: parent
        spacing: 4
        visible: !root.isVertical

        Synth.TransportButton {
            control: "seek-back"
            accentColor: root.accentColor
            visible: root.showSeek
            active: mpris.playing
            enabledButton: mpris.hasPlayer && mpris.canSeek
            Layout.preferredWidth: root.seekSize
            Layout.preferredHeight: root.seekSize
            onClicked: mpris.seekBy(-root.seekInterval)
            audioLevel: audioMon.level
            audioReactive: root.audioReactive
        }

        Synth.TransportButton {
            control: "prev"
            accentColor: root.accentColor
            active: mpris.playing
            enabledButton: mpris.hasPlayer && mpris.canGoPrevious
            Layout.preferredWidth: root.transportSize
            Layout.preferredHeight: root.transportSize
            onClicked: mpris.previous()
            audioLevel: audioMon.level
            audioReactive: root.audioReactive
        }

        Synth.TransportButton {
            control: "playpause"
            accentColor: root.accentColor
            active: mpris.playing
            enabledButton: mpris.hasPlayer && mpris.canTogglePlay
            Layout.preferredWidth: root.transportSize
            Layout.preferredHeight: root.transportSize
            onClicked: mpris.togglePlay()
            audioLevel: audioMon.level
            audioReactive: root.audioReactive
        }

        Synth.TransportButton {
            control: "next"
            accentColor: root.accentColor
            active: mpris.playing
            enabledButton: mpris.hasPlayer && mpris.canGoNext
            Layout.preferredWidth: root.transportSize
            Layout.preferredHeight: root.transportSize
            onClicked: mpris.next()
            audioLevel: audioMon.level
            audioReactive: root.audioReactive
        }

        Synth.TransportButton {
            control: "seek-forward"
            accentColor: root.accentColor
            visible: root.showSeek
            active: mpris.playing
            enabledButton: mpris.hasPlayer && mpris.canSeek
            Layout.preferredWidth: root.seekSize
            Layout.preferredHeight: root.seekSize
            onClicked: mpris.seekBy(root.seekInterval)
            audioLevel: audioMon.level
            audioReactive: root.audioReactive
        }

        Synth.SynthVolumeHorizontal {
            accentColor: root.accentColor
            volume: sysvol.level
            enabledVolume: sysvol.hasSink
            Layout.preferredWidth: root.volumeLength
            Layout.preferredHeight: root.transportSize
            onVolumeRequested: (v) => sysvol.setLevel(v)
        }
    }

    // Vertical panel: stacked transport with vertical fader (not rotated).
    ColumnLayout {
        id: verticalContent
        anchors.centerIn: parent
        spacing: 4
        visible: root.isVertical

        Synth.TransportButton {
            control: "seek-back"
            accentColor: root.accentColor
            visible: root.showSeek
            active: mpris.playing
            enabledButton: mpris.hasPlayer && mpris.canSeek
            Layout.preferredWidth: root.seekSize
            Layout.preferredHeight: root.seekSize
            Layout.alignment: Qt.AlignHCenter
            onClicked: mpris.seekBy(-root.seekInterval)
            audioLevel: audioMon.level
            audioReactive: root.audioReactive
        }

        Synth.TransportButton {
            control: "prev"
            accentColor: root.accentColor
            active: mpris.playing
            enabledButton: mpris.hasPlayer && mpris.canGoPrevious
            Layout.preferredWidth: root.transportSize
            Layout.preferredHeight: root.transportSize
            Layout.alignment: Qt.AlignHCenter
            onClicked: mpris.previous()
            audioLevel: audioMon.level
            audioReactive: root.audioReactive
        }

        Synth.TransportButton {
            control: "playpause"
            accentColor: root.accentColor
            active: mpris.playing
            enabledButton: mpris.hasPlayer && mpris.canTogglePlay
            Layout.preferredWidth: root.transportSize
            Layout.preferredHeight: root.transportSize
            Layout.alignment: Qt.AlignHCenter
            onClicked: mpris.togglePlay()
            audioLevel: audioMon.level
            audioReactive: root.audioReactive
        }

        Synth.TransportButton {
            control: "next"
            accentColor: root.accentColor
            active: mpris.playing
            enabledButton: mpris.hasPlayer && mpris.canGoNext
            Layout.preferredWidth: root.transportSize
            Layout.preferredHeight: root.transportSize
            Layout.alignment: Qt.AlignHCenter
            onClicked: mpris.next()
            audioLevel: audioMon.level
            audioReactive: root.audioReactive
        }

        Synth.TransportButton {
            control: "seek-forward"
            accentColor: root.accentColor
            visible: root.showSeek
            active: mpris.playing
            enabledButton: mpris.hasPlayer && mpris.canSeek
            Layout.preferredWidth: root.seekSize
            Layout.preferredHeight: root.seekSize
            Layout.alignment: Qt.AlignHCenter
            onClicked: mpris.seekBy(root.seekInterval)
            audioLevel: audioMon.level
            audioReactive: root.audioReactive
        }

        Synth.SynthVolumeVertical {
            accentColor: root.accentColor
            volume: sysvol.level
            enabledVolume: sysvol.hasSink
            Layout.preferredWidth: root.transportSize
            Layout.preferredHeight: root.volumeLength
            Layout.alignment: Qt.AlignHCenter
            onVolumeRequested: (v) => sysvol.setLevel(v)
        }
    }
}