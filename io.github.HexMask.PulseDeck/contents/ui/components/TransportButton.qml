// SPDX-FileCopyrightText: 2026 David Holbert
// SPDX-License-Identifier: GPL-3.0-or-later

// Layered Synth transport button: base + runtime-tinted accent mask + icon + glow.
// Never recolors the SVG sources; the white accent-mask/glow layers are
// tinted at runtime with `accentColor`.
import QtQuick
import QtQuick.Effects

Item {
    id: root

    // prev | playpause | next | seek-back | seek-forward
    property string control: "prev"
    property color accentColor: "#0ee841"
    property bool enabledButton: true
    // e.g. true while the player is Playing (slightly more engaged look)
    property bool active: false
    // Audio-reactive idle glow inputs. `audioLevel` is the smoothed 0..1
    // system peak; it only affects the idle glow while `audioReactive` is
    // on and the player is playing (`active`). Hover/pressed keep their
    // existing treatments and always take precedence.
    property real audioLevel: 0
    property bool audioReactive: false
    // Native pixel size of the artwork (64 transport / 48 seek); the
    // parent may scale the Item down for thin panels.
    property int nativeSize: control === "seek-back" || control === "seek-forward" ? 48 : 64

    signal clicked()

    readonly property string _dir: {
        switch (control) {
        case "prev": return "buttons/prev";
        case "next": return "buttons/next";
        case "playpause": return "buttons/playpause";
        case "seek-back": return "seek/back";
        case "seek-forward": return "seek/forward";
        default: return "buttons/prev";
        }
    }
    readonly property string _prefix: {
        switch (control) {
        case "prev": return "synth_prev";
        case "next": return "synth_next";
        case "playpause": return "synth_playpause";
        case "seek-back": return "synth_seek-back";
        case "seek-forward": return "synth_seek-forward";
        default: return "synth_prev";
        }
    }
    readonly property string _state: !enabledButton ? "idle" : (mouse.pressed && mouse.containsMouse ? "pressed" : (mouse.containsMouse ? "hover" : "idle"))

    function asset(layer) {
        return "../../assets/" + _dir + "/" + _prefix + "_" + _state + "_" + layer + ".svg";
    }

    // Whether the reactive idle glow is currently engaged.
    readonly property bool _reactiveActive: audioReactive && active && enabledButton

    // Expands typical mastered-music dynamics into obvious motion while
    // preserving the silence floor and peak ceiling: 0 -> 0, 0.3 -> ~0.5,
    // >=0.55 -> 1. Steeper through the mid band where real music lives.
    function pulseCurve(x) {
        const t = Math.max(0, Math.min(1, (x - 0.1) / (0.5 - 0.1)));
        return t * t * (3 - 2 * t);
    }
    readonly property real _pulseLevel: pulseCurve(Math.max(0, Math.min(1, audioLevel)))

    // Glow artwork selector. The shipped idle glow artwork is intentionally
    // empty (the approved static idle look has no halo), so a pulsing idle
    // glow needs real artwork to modulate: reuse this control's own hover
    // glow (same style, same asset family) while reactive+playing. Every
    // other combination keeps the exact state-mapped artwork, so the
    // approved static/hover/pressed looks are byte-for-byte preserved.
    function glowAsset() {
        if (_state === "idle" && _reactiveActive) {
            return "../../assets/" + _dir + "/" + _prefix + "_hover_glow.svg";
        }
        return asset("glow");
    }

    // Visual-state tuning. Hover (mask 0.9) and pressed (mask 1.0) keep
    // their approved full-brightness treatments and always override
    // instantly. The idle accent lighting goes audio-reactive only when
    // enabled and playing: silence ~0.22, medium ~0.61, peaks 1.00. Both
    // the outline mask and the symbol bind the same _maskOpacity below,
    // so they pulse synchronized exactly. Paused, toggled-off, or
    // disabled keeps the approved static idle look.
    readonly property real _audioGlow: _reactiveActive
        ? (0.06 + 0.65 * _pulseLevel) : 0.0
    readonly property real _audioMask: 0.30 + 0.70 * _pulseLevel
    readonly property real _maskOpacity: !enabledButton ? 0.35 : (_state === "pressed" ? 1.0 : (_state === "hover" ? 0.9 : ((audioReactive && active) ? _audioMask : (active ? 0.7 : 0.5))))
    readonly property real _glowOpacity: !enabledButton ? 0.0 : (_state === "pressed" ? 0.6 : (_state === "hover" ? 0.35 : ((audioReactive && active) ? _audioGlow : (active ? 0.18 : 0.0))))

    opacity: enabledButton ? 1.0 : 0.45
    Behavior on opacity { NumberAnimation { duration: 120 } }

    // 1. base hardware
    Image {
        id: baseImg
        anchors.fill: parent
        source: root.asset("base")
        smooth: true
        fillMode: Image.PreserveAspectFit
    }

    // 2. tinted accent mask (white-on-transparent source -> accent color)
    Image {
        id: maskSource
        anchors.fill: parent
        source: root.asset("accent-mask")
        smooth: true
        fillMode: Image.PreserveAspectFit
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: maskSource
        colorization: 1.2
        colorizationColor: root.accentColor
        opacity: root._maskOpacity
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    // 3. icon/symbol — same accent treatment as the outline above, so the
    // symbol and outline read as one unified backlit control. Uses the
    // identical color and the identical idle/hover/pressed opacity logic
    // (root._maskOpacity); there is no separate icon color system.
    Image {
        id: iconSource
        anchors.fill: parent
        source: root.asset("icon")
        smooth: true
        fillMode: Image.PreserveAspectFit
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: iconSource
        colorization: 1.2
        colorizationColor: root.accentColor
        opacity: root._maskOpacity
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    // 4. tinted glow. Visibility/opacity are purely declarative (see
    // glowEffect below): no imperative assignments, so live opacity
    // changes (e.g. the audio pulse) always take effect.
    Image {
        id: glowSource
        anchors.fill: parent
        source: root.glowAsset()
        smooth: true
        fillMode: Image.PreserveAspectFit
        visible: false
    }
    MultiEffect {
        id: glowEffect
        anchors.fill: parent
        source: glowSource
        colorization: 1.0
        colorizationColor: root.accentColor
        opacity: root._glowOpacity
        visible: root._glowOpacity > 0 && glowSource.status !== Image.Error
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabledButton
        cursorShape: root.enabledButton ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
