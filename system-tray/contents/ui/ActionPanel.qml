/*
    Action Panel — quick-toggle tiles + sliders shown in the expander popup.

    A Windows 11 / 10 hybrid. The hidden SNI icons grid and footer are
    composed by ExpandedRepresentation around this component.
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import QtCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3

import "components" as Components

ColumnLayout {
    id: actionPanel

    signal requestPage(string name)

    readonly property real scale: Plasmoid.configuration.scale / 100

    Layout.fillWidth: true
    spacing: 12 * actionPanel.scale

    // The previous implementation had a user identity header row here
    // (avatar + username + "Local account" subtitle), mirroring the Win11
    // panel's top-left identity card. It was removed per spec — the
    // identity card is no longer surfaced in the quick-settings panel.
    // The data plumbing (homePath/userName) was kept only as long as the
    // avatar Image needed it; now that the whole header row is gone,
    // neither is needed here.

    Components.QuickSettingsPager {
        Layout.fillWidth: true
        Layout.leftMargin: 14 * actionPanel.scale
        Layout.rightMargin: 14 * actionPanel.scale
        Layout.topMargin: 6 * actionPanel.scale
        uiScale: actionPanel.scale
        onRequestPage: name => actionPanel.requestPage(name)
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 14 * actionPanel.scale
        Layout.rightMargin: 14 * actionPanel.scale
        Layout.bottomMargin: 8 * actionPanel.scale
        columns: 3
        rowSpacing: 10 * actionPanel.scale
        columnSpacing: 0

        Components.BrightnessSlider {
            Layout.fillWidth: true
            Layout.columnSpan: 3
            visible: Plasmoid.configuration.showBrightness
            showArrow: true
            panelScreenGeometry: Plasmoid.screenGeometry
            panelScreenIndex: Plasmoid.containment.screen
            onArrowClicked: actionPanel.requestPage("brightness")
        }
        Components.VolumeSlider {
            Layout.fillWidth: true
            Layout.columnSpan: 3
            Layout.preferredHeight: 36
            visible: Plasmoid.configuration.showVolume
            onArrowClicked: actionPanel.requestPage("volume")
        }
    }

    // Bottom status bar — mirrors Win11's bottom row: battery indicator
    // (icon + percent) on the left, and a Settings button on the right.
    // The battery uses the existing Components.Battery (which wraps the
    // plasma private.battery BatteryControlModel). The Settings button
    // launches systemsettings, the KDE equivalent of Windows Settings.
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 14 * actionPanel.scale
        Layout.rightMargin: 14 * actionPanel.scale
        Layout.bottomMargin: 8 * actionPanel.scale
        spacing: 8 * actionPanel.scale

        // Battery indicator (left) — only shown if a battery is present.
        // Clicking it opens the KDE power management settings
        // (systemsettings kcm_powerdevilprofilesconfig).
        MouseArea {
            id: batteryArea
            Layout.alignment: Qt.AlignLeft
            visible: batteryIndicator.hasBattery
            implicitWidth: batteryIndicator.implicitWidth + 8 * actionPanel.scale
            implicitHeight: batteryIndicator.implicitHeight + 6 * actionPanel.scale
            hoverEnabled: true
            cursorShape: Qt.ArrowCursor
            onClicked: Qt.openUrlExternally("systemsettings://kcm_powerdevilprofilesconfig")

            // Hover highlight — a rounded-rect background that appears on
            // mouse enter, matching the visual treatment Plasma's own
            // footer buttons (Lib.FooterButton) and the Settings tool
            // button get on hover.
            Rectangle {
                anchors.fill: parent
                radius: 4 * actionPanel.scale
                color: Qt.rgba(Kirigami.Theme.textColor.r,
                               Kirigami.Theme.textColor.g,
                               Kirigami.Theme.textColor.b, 0.08)
                visible: batteryArea.containsMouse
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            Components.Battery {
                id: batteryIndicator
                anchors.centerIn: parent
            }

            PlasmaComponents3.ToolTip {
                text: batteryIndicator.charging
                    ? i18n("Charging — %1%").arg(batteryIndicator.percent)
                    : i18n("Discharging — %1%").arg(batteryIndicator.percent)
                visible: batteryArea.containsMouse
            }
        }

        Item { Layout.fillWidth: true }

        // KDE System Settings entry (right).
        PlasmaComponents3.ToolButton {
            Layout.alignment: Qt.AlignRight
            display: PlasmaComponents3.AbstractButton.IconOnly
            icon.name: "preferences-system"
            text: i18n("Settings")
            onClicked: Qt.openUrlExternally("systemsettings://")
        }
    }
}
