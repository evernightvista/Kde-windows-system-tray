#! /usr/bin/env bash
# Extract translatable strings from QML and C++ sources.
# Called by KDE's translation scripts (or manually) as:
#   Messages.sh <podir> [<srcdir>]
# It produces $podir/plasma_applet_org.kde.windowsmodern.systemtray.pot

# The directory where the .pot file should be written. Defaults to "./".
podir="${1:-.}"
# The source directory to scan. Defaults to the script's own directory.
srcdir="${2:-$(dirname "$0")}"

$XGETTEXT $(find "$srcdir" -name "*.js" -o -name "*.qml" -o -name "*.cpp" | grep -v '/tests/') -o "$podir/plasma_applet_org.kde.windowsmodern.systemtray.pot"
