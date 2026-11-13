import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property bool acOnline: false
    property string batStatus: ""
    property int batPercent: 0

    // Show when plugged in OR actively charging
    readonly property bool isChargingOrPlugged: acOnline || batStatus === "Charging"

    Timer {
        id: pollTimer
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: batProc.running = true
    }

    Process {
        id: batProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT1/status 2>/dev/null; cat /sys/class/power_supply/BAT1/capacity 2>/dev/null; cat /sys/class/power_supply/ACAD/online 2>/dev/null"]

        stdout: SplitParser {
            id: parser
            property var buffer: []
            onRead: line => buffer.push(line.trim())
        }

        onExited: (exitCode) => {
            var b = parser.buffer;
            if (b.length >= 3) {
                root.batStatus = b[0];
                root.batPercent = parseInt(b[1]) || 0;
                root.acOnline = (b[2] === "1");
            }
            parser.buffer = [];
        }
    }

    horizontalBarPill: Component {
        Row {
            id: row
            spacing: Theme.spacingXS
            visible: root.isChargingOrPlugged

            DIcon {
                id: boltIcon
                name: "bolt"
                size: Theme.iconSize
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on opacity {
                    running: root.isChargingOrPlugged
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
                }
            }

            StyledText {
                text: root.batPercent + "%"
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS
            visible: root.isChargingOrPlugged

            DIcon {
                name: "bolt"
                size: Theme.iconSize
                color: Theme.primary
                anchors.horizontalCenter: parent.horizontalCenter

                SequentialAnimation on opacity {
                    running: root.isChargingOrPlugged
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
                }
            }

            StyledText {
                text: root.batPercent + "%"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}

