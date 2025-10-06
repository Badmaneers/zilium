import QtQuick 2.15

QtObject {
    id: themeManager
    
    property bool isDark: true
    
    // Dark theme colors
    readonly property color darkBackground: "#232629"
    readonly property color darkSurface: "#31363b"
    readonly property color darkPrimaryText: "#eff0f1"
    readonly property color darkSecondaryText: "#bdc3c7"
    readonly property color darkBorder: "#4d5254"
    readonly property color darkButton: "#31363b"
    readonly property color darkButtonHover: "#3c4245"
    readonly property color darkConsole: "#1e1e1e"
    
    // Light theme colors
    readonly property color lightBackground: "#fcfcfc"
    readonly property color lightSurface: "#ffffff"
    readonly property color lightPrimaryText: "#232629"
    readonly property color lightSecondaryText: "#6e6e6e"
    readonly property color lightBorder: "#e0e0e0"
    readonly property color lightButton: "#f5f5f5"
    readonly property color lightButtonHover: "#eeeeee"
    readonly property color lightConsole: "#fafafa"
    
    // Accent color (same for both themes)
    readonly property color accent: "#3daee9"
    
    // Current theme colors
    readonly property color backgroundColor: isDark ? darkBackground : lightBackground
    readonly property color surfaceColor: isDark ? darkSurface : lightSurface
    readonly property color primaryTextColor: isDark ? darkPrimaryText : lightPrimaryText
    readonly property color secondaryTextColor: isDark ? darkSecondaryText : lightSecondaryText
    readonly property color borderColor: isDark ? darkBorder : lightBorder
    readonly property color buttonColor: isDark ? darkButton : lightButton
    readonly property color buttonHoverColor: isDark ? darkButtonHover : lightButtonHover
    readonly property color consoleBackground: isDark ? darkConsole : lightConsole
    readonly property color accentColor: accent
    
    function toggleTheme() {
        isDark = !isDark
    }
}
