import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import "../lib" as Lib
import "../js/colorType.js" as ColorType

Lib.Tile {
    id: tile

    property bool darkMode: ColorType.isDark(Kirigami.Theme.backgroundColor)

    label: darkMode ? i18n("Dark Mode") : i18n("Light Mode")
    iconSource: darkMode ? "weather-clear-night-symbolic" : "weather-clear-symbolic"
    active: false

    // Switch the Plasma color scheme only, via the dedicated
    // plasma-apply-colorscheme CLI (kcms/colors/plasma-apply-colorscheme.cpp).
    // The previous implementation called `plasma-apply-lookandfeel --apply`,
    // which applies a whole Look-and-Feel package (window decorations, plasma
    // theme, splash screen, etc.) and required the user to have those LaF
    // packages installed; the configured defaults ("org.kde.windowsmodern.dark"
    // / ".light") were LaF IDs that don't exist on a stock Plasma 6 install, so
    // the call silently failed and the toggle appeared to do nothing.
    //
    // plasma-apply-colorscheme takes a color scheme NAME (matching a file in
    // share/color-schemes/<name>.colors) and applies just the palette — see
    // plasma-apply-colorscheme.cpp:42-44, 81-112. With Breeze Light / Breeze
    // Dark as the new config defaults (see contents/config/main.xml), the
    // scheme is guaranteed to exist on every Plasma 6 install. KWin's
    // BlendChanges animation is started by the binary itself before applying,
    // so the transition is the standard Plasma one.
    onClicked: {
        var target = darkMode ? Plasmoid.configuration.lightTheme : Plasmoid.configuration.darkTheme;
        darkMode = !darkMode;
        colorschemeExec.exec("plasma-apply-colorscheme " + target);
    }

    onMiddleClicked: {
        darkMode = !darkMode;
        var target = darkMode ? Plasmoid.configuration.darkTheme : Plasmoid.configuration.lightTheme;
        colorschemeExec.exec("plasma-apply-colorscheme " + target);
    }

    tooltipText: darkMode ? i18n("Switch to light mode") : i18n("Switch to dark mode")

    Plasma5Support.DataSource {
        id: colorschemeExec
        engine: "executable"
        connectedSources: []
        onNewData: function (sourceName, data) {
            disconnectSource(sourceName);
        }
        function exec(cmd) {
            connectSource(cmd);
        }
    }
}
