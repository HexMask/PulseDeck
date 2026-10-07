// SPDX-FileCopyrightText: 2026 David Holbert
// SPDX-License-Identifier: GPL-3.0-or-later

// Vertical Synth volume fader: track + draggable handle (top = max).
import QtQuick
import QtQuick.Effects

Item {
    id: root

    property color accentColor: "#0ee841"
    property real volume: 0.5
    property bool enabledVolume: true

    signal volumeRequested(real value)

    implicitWidth: 40
    implicitHeight: 150

    readonly property string _trackBase: "../../assets/volume/vertical/synth_volume-vertical_track_base.svg"
    readonly property string _trackMask: "../../assets/volume/vertical/synth_volume-vertical_track_accent-mask.svg"
    readonly property string _hState: !enabledVolume ? "idle" : ((dragArea.pressed && dragArea.containsMouse) || handleHover.containsMouse ? (dragArea.pressed ? "pressed" : "hover") : "idle")

    function handleAsset(layer) {
        return "../../assets/volume/vertical/synth_volume-vertical_handle_" + _hState + "_" + layer + ".svg";
    }

    opacity: enabledVolume ? 1.0 : 0.45

    // Track (stretched to the component height)
    Image {
        id: trackBase
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.height * (28 / 180)
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

    // Handle (top = full volume)
    readonly property real _handleH: width * (28 / 40)
    Item {
        id: handle
        width: parent.width
        height: root._handleH
        x: 0
        y: Math.max(0, Math.min(parent.height - height, (1 - root.volume) * (parent.height - height)))

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
        // Note: vertical handle artwork ships without a glow layer, so no
        // glow stage here (graceful by design, not by error-hiding).
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

        function applyVolume(mouseY) {
            const v = Math.max(0, Math.min(1, 1 - mouseY / height));
            root.volumeRequested(v);
        }
        onPressed: (mouse) => applyVolume(mouse.y)
        onPositionChanged: (mouse) => {
            if (pressed) {
                applyVolume(mouse.y);
            }
        }
        onWheel: (wheel) => {
            const step = 0.05;
            const v = Math.max(0, Math.min(1, root.volume + (wheel.angleDelta.y > 0 ? step : -step)));
            root.volumeRequested(v);
        }
    }
}
