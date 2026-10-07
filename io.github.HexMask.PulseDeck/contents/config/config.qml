// SPDX-FileCopyrightText: 2026 David Holbert
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: "General"
        icon: "preferences-system"
        source: "ConfigGeneral.qml"
    }
}
