/*
    SPDX-FileCopyrightText: 2011 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.core as PlasmaCore

KSvg.FrameSvgItem {
    id: currentItemHighLight

    property int location

    property bool animationEnabled: true
    property var highlightedItem: null

    property var containerMargins: {
        let item = currentItemHighLight;
        while (item.parent) {
            item = item.parent;
            if (item.isAppletContainer) {
                return item.getMargins;
            }
        }
        return undefined;
    }

    z: -1 // always draw behind icons

    imagePath: "widgets/tabbar"
    prefix: {
        let prefix;
        switch (location) {
        case PlasmaCore.Types.LeftEdge:
            prefix = "west-active-tab";
            break;
        case PlasmaCore.Types.TopEdge:
            prefix = "north-active-tab";
            break;
        case PlasmaCore.Types.RightEdge:
            prefix = "east-active-tab";
            break;
        default:
            prefix = "south-active-tab";
        }
        if (!hasElementPrefix(prefix)) {
            prefix = "active-tab";
        }
        return prefix;
    }

    // update when System Tray is expanded - applet activated or hidden icons shown
    Connections {
        target: systemTrayState

        function onActiveAppletChanged() {
            Qt.callLater(currentItemHighLight.updateHighlightedItem);
        }

        function onExpandedChanged() {
            Qt.callLater(currentItemHighLight.updateHighlightedItem);
        }

        // actionPanelShowing is derived from expanded && !activeApplet &&
        // !hiddenItemsRequested. The two handlers above cover changes in
        // expanded and activeApplet, but a transition between the "Show
        // hidden items" view and the Action Panel keeps both of those
        // unchanged (activeApplet stays null, expanded stays true) and only
        // flips hiddenItemsRequested — which would otherwise leave the
        // highlight stuck on its previous target.
        function onHiddenItemsRequestedChanged() {
            Qt.callLater(currentItemHighLight.updateHighlightedItem);
        }
    }

    // update when applet changes parent (e.g. moves from active to hidden icons)
    Connections {
        target: systemTrayState.activeApplet

        function onParentChanged() {
            Qt.callLater(updateHighlightedItem);
        }
    }

    // update when System Tray size changes
    Connections {
        target: parent

        function onWidthChanged() {
            Qt.callLater(updateHighlightedItem);
        }

        function onHeightChanged() {
            Qt.callLater(updateHighlightedItem);
        }
    }

    // update when scale of newly added tray item changes (check 'add' animation in GridView in main.qml)
    Connections {
        target: !!currentItemHighLight.highlightedItem && currentItemHighLight.highlightedItem.parent ? currentItemHighLight.highlightedItem.parent : null

        function onScaleChanged() {
            Qt.callLater(currentItemHighLight.updateHighlightedItem);
        }
    }

    function updateHighlightedItem() {
        if (systemTrayState.expanded) {
            // Action Panel (system-cluster quick settings) is open: highlight
            // only the cluster container (Network/Volume/Battery group),
            // using the same Plasma 6 tabbar SVG used for a single active
            // applet. Without this branch, actionPanelShowing leaves
            // activeApplet null (showActionPanel calls setActiveApplet(null)),
            // so the previous logic fell through to the "Show hidden items"
            // else-branch and highlighted `parent` (the whole tray) — which
            // incorrectly highlighted every SNI icon too. forceEdgeHighlight
            // is false so the tabbar sizes to the cluster (plus container
            // margins when the tray is a single row/column, matching the
            // per-applet active highlight).
            if (systemTrayState.actionPanelShowing && parent.clusterContainer) {
                changeHighlightedItem(parent.clusterContainer, /*forceEdgeHighlight*/false);
            } else if (systemTrayState.activeApplet && systemTrayState.activeApplet.parent && systemTrayState.activeApplet.parent.inVisibleLayout) {
                changeHighlightedItem(systemTrayState.activeApplet.parent.container, /*forceEdgeHighlight*/false);
            } else { // 'Show hidden items' popup
                changeHighlightedItem(parent, /*forceEdgeHighlight*/true);
            }
        } else {
            highlightedItem = null;
        }
        currentItemHighLight.opacity = systemTrayState.expanded ? 1 : 0
    }

    function changeHighlightedItem(nextItem, forceEdgeHighlight) {
        // do not animate the first appearance
        // or when the property value of a highlighted item changes
        if (!highlightedItem || (highlightedItem === nextItem)) {
            animationEnabled = false;
        }

        const p = parent.mapFromItem(nextItem, 0, 0);
        if (containerMargins && (parent.oneRowOrColumn || forceEdgeHighlight)) {
            x = p.x - containerMargins('left', /*returnAllMargins*/true);
            y = p.y - containerMargins('top', /*returnAllMargins*/true);
            width = nextItem.width + containerMargins('left', /*returnAllMargins*/true) + containerMargins('right', /*returnAllMargins*/true);
            height = nextItem.height + containerMargins('bottom', /*returnAllMargins*/true) + containerMargins('top', /*returnAllMargins*/true);
        } else {
            x = p.x;
            y = p.y;
            width = nextItem.width;
            height = nextItem.height;
        }

        highlightedItem = nextItem;
        animationEnabled = true;
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: systemTrayState.expanded ? Easing.OutCubic : Easing.InCubic
        }
    }
    Behavior on x {
        id: xAnim
        enabled: currentItemHighLight.animationEnabled
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutCubic
        }
    }
    Behavior on y {
        id: yAnim
        enabled: currentItemHighLight.animationEnabled
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutCubic
        }
    }
    Behavior on width {
        id: widthAnim
        enabled: currentItemHighLight.animationEnabled
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutCubic
        }
    }
    Behavior on height {
        id: heightAnim
        enabled: currentItemHighLight.animationEnabled
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutCubic
        }
    }
}
