/*
    SPDX-FileCopyrightText: 2020 Konrad Materka <materka@gmail.com>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

//This object contains state of the SystemTray, mainly related to the 'expanded' state
QtObject {
    id: systemTrayState
    //true if System Tray is 'expanded'. It may be when:
    // - there is an active applet or
    // - 'Status and Notification' with hidden items is shown
    // - the Action Panel (system-cluster quick settings) is shown
    property bool expanded: false
    //set when there is an applet selected
    property Item activeApplet

    // True while the popup should show the "Show Hidden Icons" grid rather
    // than the Action Panel. Only meaningful while expanded is true and
    // activeApplet is null; ExpandedRepresentation.qml uses it to pick
    // between the two. This is the "minimal additional state" needed on
    // top of activeApplet to distinguish the two flavors of that view,
    // per the system-cluster/hidden-icons split.
    property bool hiddenItemsRequested: false

    // Snapshot of `hiddenItemsRequested` taken right before an applet was
    // activated. When the user backs out of that applet (the back button
    // calls setActiveApplet(null)) we restore the view that was on screen
    // before the applet opened, instead of always falling through to the
    // Action Panel. This makes the ExpanderArrow (^) flow behave:
    //   1. press ^                  -> showHiddenItems()  (hidden grid shown)
    //   2. tap an entry e.g. Vault  -> setActiveApplet(vault)
    //   3. press back               -> setActiveApplet(null)
    // should land back on the hidden grid from step 1, not the Action Panel.
    // Entering an applet from the Action Panel (e.g. a flyout reached via a
    // tile's arrow) leaves this as false, so back still returns to the panel.
    property bool hiddenItemsBeforeActiveApplet: false

    //allow expanded change only when activated at least once
    //this is to suppress expanded state change during Plasma startup
    property bool acceptExpandedChange: false

    // These properties allow us to keep track of where the expanded applet
    // was and is on the panel, allowing PlasmoidPopupContainer.qml to animate
    // depending on their locations.
    property int oldVisualIndex: -1
    property int newVisualIndex: -1

    // Whether the popup is currently showing the Action Panel specifically
    // (as opposed to Hidden Items or a native/themed applet flyout). Panel
    // controls that self-toggle the popup (ExpanderArrow, and the system
    // cluster's own click handling in PlasmoidItem.qml) read this — or
    // hiddenItemsShowing below — at mouse-press time and act on that
    // snapshot at click time, mirroring ExpanderArrow's original wasExpanded
    // pattern: hideOnWindowDeactivate can auto-close the popup as soon as
    // the press steals focus from it, while `expanded` itself only syncs
    // back up to ~100ms later (see the expandedSync Timer in main.qml), so
    // reading live state at click time is not reliable.
    readonly property bool actionPanelShowing: expanded && !activeApplet && !hiddenItemsRequested
    readonly property bool hiddenItemsShowing: expanded && !activeApplet && hiddenItemsRequested

    // The three Plasma applets that form the Windows 11–style system
    // cluster (Network + Volume + Battery); see root.systemClusterPluginIds
    // in main.qml, which is the single source of truth this delegates to.
    function isSystemClusterApplet(applet) {
        return !!applet && !!applet.Plasmoid && root.systemClusterPluginIds.indexOf(applet.Plasmoid.pluginName) >= 0
    }

    // Opens the Action Panel (quick-toggle tiles + sliders), clearing any
    // active applet and any pending hidden-items request. This is the one
    // destination for primary activation of the system cluster, and the
    // fallback destination for any indirect activation of one of its three
    // applets (e.g. a global keyboard shortcut assigned directly to one of
    // them — see the guard in setActiveApplet below).
    function showActionPanel() {
        setActiveApplet(null)
        hiddenItemsRequested = false
        expanded = true
    }

    // Opens the "Show Hidden Icons" popup. This is ExpanderArrow's one job.
    function showHiddenItems() {
        setActiveApplet(null)
        hiddenItemsRequested = true
        expanded = true
    }

    function setActiveApplet(applet, visualIndex, allowDetailPage) {
        // The system cluster's tray icons must never activate their own
        // native/themed popup directly — only explicit in-panel detail
        // navigation (ExpandedRepresentation.activateFlyout, which passes
        // allowDetailPage=true) may do so. Routing this here — before any
        // popup becomes visible — rather than only in the click handler
        // also protects against indirect activation paths that bypass
        // PlasmoidItem.qml entirely, such as a global keyboard shortcut
        // assigned directly to one of the three plasmoids.
        if (applet && !allowDetailPage && isSystemClusterApplet(applet)) {
            showActionPanel()
            return
        }

        // Applets which prefer to always show their full
        // representation will always be expanded, there's
        // no need to activate them.
        if (applet && applet.preferredRepresentation == applet.fullRepresentation) return;

        if (visualIndex === undefined) {
            oldVisualIndex = -1
            newVisualIndex = -1
        } else {
            oldVisualIndex = (activeApplet && activeApplet.status === PlasmaCore.Types.PassiveStatus) ? 9999 : newVisualIndex
            newVisualIndex = visualIndex
        }

        const oldApplet = activeApplet
        if (applet && !applet.preferredRepresentation) {
            applet.expanded = true;
        }
        if (!applet || !applet.preferredRepresentation) {
            activeApplet = applet;
        }

        if (oldApplet && oldApplet !== applet) {
            oldApplet.expanded = false
        }

        if (applet && !applet.preferredRepresentation) {
            expanded = true
        }

        // An applet is now active (ordinary tray icon, or a cluster detail
        // page reached via activateFlyout). Stash the view we were on before
        // opening it and leave the active applet covering that view; when the
        // user later backs out (setActiveApplet(null)) we restore the stashed
        // view rather than always dropping to the Action Panel.
        if (applet) {
            hiddenItemsBeforeActiveApplet = hiddenItemsRequested
            hiddenItemsRequested = false
        } else {
            // Back navigation: return to whichever view was showing before
            // the applet opened (hidden grid or Action Panel).
            hiddenItemsRequested = hiddenItemsBeforeActiveApplet
            hiddenItemsBeforeActiveApplet = false
        }
    }

    onExpandedChanged: {
        if (expanded) {
            Plasmoid.status = PlasmaCore.Types.RequiresAttentionStatus
        } else {
            Plasmoid.status = PlasmaCore.Types.PassiveStatus;
            if (activeApplet) {
                // if not expanded we don't have an active applet anymore
                activeApplet.expanded = false
                activeApplet = null
            }
            hiddenItemsRequested = false
            hiddenItemsBeforeActiveApplet = false
        }
        acceptExpandedChange = false
        root.expanded = expanded
    }

    //listen on SystemTray AppletInterface signals
    readonly property Connections plasmoidConnections: Connections {
        target: Plasmoid
        //emitted when activation is requested, for example by using a global keyboard shortcut
        function onActivated() {
            systemTrayState.acceptExpandedChange = true
        }
    }

    readonly property Connections rootConnections: Connections {
        function onExpandedChanged() {
            if (systemTrayState.acceptExpandedChange) {
                systemTrayState.expanded = root.expanded
            } else {
                root.expanded = systemTrayState.expanded
            }
        }
    }

    readonly property Connections activeAppletConnections: Connections {
        target: systemTrayState.activeApplet

        function onExpandedChanged() {
            if (systemTrayState.activeApplet && !systemTrayState.activeApplet.expanded) {
                systemTrayState.expanded = false
            }
        }
    }
}
