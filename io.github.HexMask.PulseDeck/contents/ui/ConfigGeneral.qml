// SPDX-FileCopyrightText: 2026 David Holbert
// SPDX-License-Identifier: GPL-3.0-or-later

// Compact settings page: accent color, seek options, player selection.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.private.mpris as Mpris

KCM.SimpleKCM {
    id: root

    property string cfg_accentColor
    property alias cfg_showSeekButtons: showSeek.checked
    property alias cfg_seekInterval: seekInterval.value
    property alias cfg_audioReactiveGlow: audioReactiveGlow.checked
    property alias cfg_automaticPlayer: automaticPlayer.checked
    property alias cfg_manualPlayer: manualPlayer.text

    // Live probe of MPRIS names so users can pick the right identity.
    property var _probe: Mpris.Mpris2Model {
        id: probe
        readonly property int containerRole: Qt.UserRole + 1
        function names() {
            const out = [];
            for (let i = 0; i < rowCount(); i++) {
                const p = data(index(i, 0), containerRole);
                if (p && p.identity) {
                    out.push(p.identity);
                }
            }
            return out;
        }
    }
    property string detectedText: probe.names().join(", ")
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.detectedText = probe.names().join(", ")
    }

    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            text: "Appearance"
            level: 3
        }

        Kirigami.FormLayout {
            RowLayout {
                Kirigami.FormData.label: "Accent color:"
                spacing: Kirigami.Units.smallSpacing

                Rectangle {
                    id: accentPreview
                    width: 32
                    height: 24
                    radius: 4
                    color: /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(accentField.text) ? accentField.text : "#0ee841"
                    border.color: Kirigami.Theme.textColor
                    border.width: 1
                }
                TextField {
                    id: accentField
                    text: root.cfg_accentColor
                    placeholderText: "#0ee841"
                    maximumLength: 9
                    onEditingFinished: {
                        if (/^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(text)) {
                            root.cfg_accentColor = text;
                        } else {
                            text = root.cfg_accentColor;
                        }
                    }
                }
                Button {
                    text: "Pick…"
                    onClicked: accentDialog.open()
                }
                ColorDialog {
                    id: accentDialog
                    selectedColor: accentPreview.color
                    options: ColorDialog.ShowAlphaChannel
                    onAccepted: {
                        const c = selectedColor;
                        const hex = "#" + ("00" + Math.round(c.r * 255).toString(16)).slice(-2)
                            + ("00" + Math.round(c.g * 255).toString(16)).slice(-2)
                            + ("00" + Math.round(c.b * 255).toString(16)).slice(-2);
                        accentField.text = hex;
                        root.cfg_accentColor = hex;
                    }
                }
            }
        }

        Kirigami.Heading {
            text: "Glow"
            level: 3
            Layout.topMargin: Kirigami.Units.largeSpacing
        }

        Kirigami.FormLayout {
            CheckBox {
                id: audioReactiveGlow
                Kirigami.FormData.label: "Idle glow:"
                text: "Audio-reactive glow"
                checked: root.cfg_audioReactiveGlow
            }
        }

        Kirigami.Heading {
            text: "Seek"
            level: 3
            Layout.topMargin: Kirigami.Units.largeSpacing
        }

        Kirigami.FormLayout {
            CheckBox {
                id: showSeek
                Kirigami.FormData.label: "Seek buttons:"
                text: "Show seek backward / forward"
                checked: root.cfg_showSeekButtons
            }
            SpinBox {
                id: seekInterval
                Kirigami.FormData.label: "Seek interval (s):"
                from: 1
                to: 120
                value: root.cfg_seekInterval || 10
                enabled: showSeek.checked
            }
        }

        Kirigami.Heading {
            text: "Player"
            level: 3
            Layout.topMargin: Kirigami.Units.largeSpacing
        }

        Kirigami.FormLayout {
            CheckBox {
                id: automaticPlayer
                Kirigami.FormData.label: "Selection:"
                text: "Automatically follow the active player"
                checked: root.cfg_automaticPlayer
            }
            TextField {
                id: manualPlayer
                Kirigami.FormData.label: "Manual player:"
                placeholderText: "e.g. Brave, Firefox, VLC, Spotify"
                text: root.cfg_manualPlayer
                enabled: !automaticPlayer.checked
            }
        }

        Label {
            text: root.detectedText.length > 0
                ? "Detected MPRIS players: " + root.detectedText
                : "No MPRIS players detected right now."
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            font.italic: true
            opacity: 0.8
        }
    }
}
