// SPDX-FileCopyrightText: 2026 David Holbert
// SPDX-License-Identifier: GPL-3.0-or-later

// Horizontal Synth volume fader: track + draggable handle.
// Layers follow the asset system; white masks are tinted at runtime.
import QtQuick
import QtQuick.Effects

Item {
    id: root

    property color accentColor: "#0ee841"
    property real volume: 0.5
    property bool enabledVolume: true

    signal volumeRequested(real value)

    implicitWidth: 150
    implicitHeight: 40

    readonly property string _trackBase: "../../assets/volume/horizontal/synth_volume-horizontal_track_base.svg"
    readonly property string _trackMask: "../../assets/volume/horizontal/synth_volume-horizontal_track_accent-mask.svg"
    readonly property string _hState: !enabledVolume ? "idle" : ((dragArea.pressed && dragArea.containsMouse) || handleHover.containsMouse ? (dragArea.pressed ? "pressed" : "hover") : "idle")

    function handleAsset(layer) {
        return "../../assets/volume/horizontal/synth_volume-horizontal_handle_" + _hState + "_" + layer + ".svg";
    }

    opacity: enabledVolume ? 1.0 : 0.45

    // Track (stretched to the component width)
    Image {
        id: trackBase
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: parent.width * (28 / 180)
        source: root._trackBase
        smooth: true
        fillMode: Image.Stretch
    }
    Image {
        id: trackMaskSource
        anchors.fill: trackBase
        source: root._trackMask
        smooth: true
        fillMode: Image.Stretch
        visible: false
    }
    MultiEffect {
        anchors.fill: trackBase
        source: trackMaskSource
        colorization: 1.0
        colorizationColor: root.accentColor
        opacity: root.enabledVolume ? 0.75 : 0.3
    }

    // Handle
    readonly property real _handleW: height * (28 / 40)
    Item {
        id: handle
        width: root._handleW
        height: parent.height
        x: Math.max(0, Math.min(parent.width - width, root.volume * (parent.width - width)))
        y: 0

        Image {
            anchors.fill: parent
            source: root.handleAsset("base")
            smooth: true
            fillMode: Image.PreserveAspectFit
        }
        Image {
            id: hMaskSource
            anchors.fill: parent
            source: root.handleAsset("accent-mask")
            smooth: true
            fillMode: Image.PreserveAspectFit
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: hMaskSource
            colorization: 1.0
            colorizationColor: root.accentColor
            opacity: root._hState === "pressed" ? 1.0 : (root._hState === "hover" ? 0.9 : 0.55)
        }
        // Glow visibility/opacity stay purely declarative: assigning to
        // hGlowEffect.visible here would replace its binding and freeze it.
        Image {
            id: hGlowSource
            anchors.fill: parent
            source: root.handleAsset("glow")
            smooth: true
            fillMode: Image.PreserveAspectFit
            visible: false
        }
        MultiEffect {
            id: hGlowEffect
            anchors.fill: parent
            source: hGlowSource
            colorization: 1.0
            colorizationColor: root.accentColor
            opacity: root._hState === "pressed" ? 0.6 : (root._hState === "hover" ? 0.35 : 0.0)
            visible: opacity > 0 && hGlowSource.status !== Image.Error
        }
        MouseArea {
            id: handleHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabledVolume
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function applyVolume(mouseX) {
            const v = Math.max(0, Math.min(1, mouseX / width));
            root.volumeRequested(v);
        }
        onPressed: (mouse) => applyVolume(mouse.x)
        onPositionChanged: (mouse) => {
            if (pressed) {
                applyVolume(mouse.x);
            }
        }
        onWheel: (wheel) => {
            const step = 0.05;
            const v = Math.max(0, Math.min(1, root.volume + (wheel.angleDelta.y > 0 ? step : -step)));
            root.volumeRequested(v);
        }
    }
}
