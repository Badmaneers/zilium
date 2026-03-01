import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import QtQuick.Window 2.15

Window {
    id: guideWindow
    title: "Zilium Super Compactor - User Guide"
    width: 950
    height: 750
    minimumWidth: 800
    minimumHeight: 600
    
    flags: Qt.Window | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint
    
    color: "#1e1e1e"
    
    // Center on screen when shown
    Component.onCompleted: {
        x = Screen.width / 2 - width / 2
        y = Screen.height / 2 - height / 2
    }
    
    property color primaryTextColor: "#e0e0e0"
    property color secondaryTextColor: "#b0b0b0"
    property color accentColor: "#64b5f6"
    property color surfaceColor: "#252526"
    property color codeBackground: "#2d2d2d"
    property color borderColor: "#404040"
    property color successColor: "#4caf50"
    property color warningColor: "#ff9800"
    property color errorColor: "#f44336"
    
    // Function to show the window
    function show() {
        visible = true
        raise()
        requestActivate()
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        
        ColumnLayout {
            width: guideWindow.width - 100
            spacing: 24
            
            // Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                color: accentColor
                radius: 8
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    
                    Label {
                        text: "🚀 Zilium Super Compactor"
                        font.pixelSize: 28
                        font.bold: true
                        color: "#ffffff"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Label {
                        text: "Android Super Partition Builder Tool"
                        font.pixelSize: 16
                        color: "#e3f2fd"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Label {
                        text: "Version 2.0"
                        font.pixelSize: 12
                        color: "#bbdefb"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
            
            // Quick Start Section
            Label {
                text: "📖 Quick Start Guide"
                font.pixelSize: 20
                font.bold: true
                color: accentColor
                Layout.topMargin: 8
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: quickStartContent.implicitHeight + 40
                color: surfaceColor
                radius: 8
                border.color: borderColor
                border.width: 1
                
                ColumnLayout {
                    id: quickStartContent
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16
                    
                    // GUI Steps
                    Label {
                        text: "GUI Usage:"
                        font.pixelSize: 16
                        font.bold: true
                        color: primaryTextColor
                    }
                    
                    Repeater {
                        model: [
                            "1. Click 'Browse...' next to 'Select .json file'",
                            "2. Navigate to your ROM's META folder and select super_def.json",
                            "3. Click 'Browse...' to select output directory",
                            "4. Review validation in Super Info tab (must be ✓ green)",
                            "5. Click 'Start Compiling' button",
                            "6. Wait for build to complete",
                            "7. Click 'Verify Output Image' to check result"
                        ]
                        
                        delegate: Label {
                            text: modelData
                            color: secondaryTextColor
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: borderColor
                        Layout.topMargin: 8
                        Layout.bottomMargin: 8
                    }
                    
                    // Tab Descriptions
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 16
                        rowSpacing: 12
                        
                        Label { text: "📊 Super Info:"; font.bold: true; color: accentColor; font.pixelSize: 13 }
                        Label { text: "Device metadata, validation status, estimated time"; color: secondaryTextColor; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        
                        Label { text: "📦 Partitions:"; font.bold: true; color: accentColor; font.pixelSize: 13 }
                        Label { text: "Enable/disable partitions, browse custom images"; color: secondaryTextColor; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        
                        Label { text: "🖥️ Console Log:"; font.bold: true; color: accentColor; font.pixelSize: 13 }
                        Label { text: "Real-time build output and error messages"; color: secondaryTextColor; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        
                        Label { text: "⚙️ Settings:"; font.bold: true; color: accentColor; font.pixelSize: 13 }
                        Label { text: "Theme toggle, guide, license"; color: secondaryTextColor; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    }
                }
            }
            
            // CLI Usage Section
            Label {
                text: "💻 CLI Usage"
                font.pixelSize: 20
                font.bold: true
                color: accentColor
                Layout.topMargin: 16
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: cliContent.implicitHeight + 40
                color: codeBackground
                radius: 8
                border.color: borderColor
                border.width: 1
                
                ColumnLayout {
                    id: cliContent
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12
                    
                    Label {
                        text: "Basic syntax:"
                        font.pixelSize: 13
                        font.bold: true
                        color: primaryTextColor
                    }
                    
                    Label {
                        text: "./zilium-super-compactor <ROM_DIR>"
                        font.family: "monospace"
                        color: successColor
                        font.pixelSize: 12
                    }
                    
                    Label {
                        text: "With specific config file:"
                        font.pixelSize: 13
                        font.bold: true
                        color: primaryTextColor
                        Layout.topMargin: 8
                    }
                    
                    Label {
                        text: "./zilium-super-compactor <ROM_DIR> <CONFIG_FILE.json>"
                        font.family: "monospace"
                        color: successColor
                        font.pixelSize: 12
                    }
                    
                    Label {
                        text: "With custom output directory:"
                        font.pixelSize: 13
                        font.bold: true
                        color: primaryTextColor
                        Layout.topMargin: 8
                    }
                    
                    Label {
                        text: "./zilium-super-compactor <ROM_DIR> <CONFIG_FILE.json> <OUTPUT_DIR>"
                        font.family: "monospace"
                        color: successColor
                        font.pixelSize: 12
                    }
                }
            }
            
            // Validation System
            Label {
                text: "✅ Validation System"
                font.pixelSize: 20
                font.bold: true
                color: accentColor
                Layout.topMargin: 16
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    color: surfaceColor
                    radius: 8
                    border.color: successColor
                    border.width: 2
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        
                        Label {
                            text: "✓ Success"
                            font.pixelSize: 16
                            font.bold: true
                            color: successColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Label {
                            text: "All checks passed"
                            font.pixelSize: 11
                            color: secondaryTextColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    color: surfaceColor
                    radius: 8
                    border.color: warningColor
                    border.width: 2
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        
                        Label {
                            text: "⚠ Warning"
                            font.pixelSize: 16
                            font.bold: true
                            color: warningColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Label {
                            text: "Non-critical issues"
                            font.pixelSize: 11
                            color: secondaryTextColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    color: surfaceColor
                    radius: 8
                    border.color: errorColor
                    border.width: 2
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        
                        Label {
                            text: "✗ Error"
                            font.pixelSize: 16
                            font.bold: true
                            color: errorColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Label {
                            text: "Build blocked"
                            font.pixelSize: 11
                            color: secondaryTextColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
            
            // A/B Slot Support
            Label {
                text: "📱 A/B Slot Support"
                font.pixelSize: 20
                font.bold: true
                color: accentColor
                Layout.topMargin: 16
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: abSlotContent.implicitHeight + 40
                color: surfaceColor
                radius: 8
                border.color: borderColor
                border.width: 1
                
                ColumnLayout {
                    id: abSlotContent
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12
                    
                    Label {
                        text: "Zilium intelligently handles A/B slot devices:"
                        font.pixelSize: 14
                        color: primaryTextColor
                    }
                    
                    Label {
                        text: "• Single-slot builds (only _a or _b): Shows warnings but allows build\n• Dual-slot builds (_a and _b): Full validation\n• Missing both slots: Build blocked with error"
                        color: secondaryTextColor
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                    
                    Label {
                        text: "Flashing: fastboot flash super super.img"
                        font.family: "monospace"
                        color: accentColor
                        font.pixelSize: 12
                        Layout.topMargin: 8
                    }
                }
            }
            
            // Tips & Tricks
            Label {
                text: "💡 Tips & Tricks"
                font.pixelSize: 20
                font.bold: true
                color: accentColor
                Layout.topMargin: 16
            }
            
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 12
                rowSpacing: 12
                
                Repeater {
                    model: [
                        {icon: "🎨", title: "Theme Toggle", desc: "Switch between dark/light mode in Settings tab"},
                        {icon: "💾", title: "Save Configs", desc: "Modified configs are saved automatically before build"},
                        {icon: "🔍", title: "Re-validate", desc: "Click Re-validate after editing partition paths"},
                        {icon: "⏱️", title: "Build Time", desc: "Estimated time shown based on partition sizes (~100MB/s)"},
                        {icon: "🛡️", title: "VBMeta", desc: "Rebuilt super.img requires disabled vbmeta verification"},
                        {icon: "📋", title: "Console Log", desc: "Copy output for debugging or sharing with support"}
                    ]
                    
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 90
                        color: surfaceColor
                        radius: 8
                        border.color: borderColor
                        border.width: 1
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4
                            
                            Label {
                                text: modelData.icon + " " + modelData.title
                                font.pixelSize: 14
                                font.bold: true
                                color: primaryTextColor
                            }
                            
                            Label {
                                text: modelData.desc
                                font.pixelSize: 11
                                color: secondaryTextColor
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
            
            // Troubleshooting
            Label {
                text: "🔧 Troubleshooting"
                font.pixelSize: 20
                font.bold: true
                color: accentColor
                Layout.topMargin: 16
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: troubleshootContent.implicitHeight + 40
                color: surfaceColor
                radius: 8
                border.color: errorColor
                border.width: 1
                
                ColumnLayout {
                    id: troubleshootContent
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12
                    
                    Label {
                        text: "Common Issues:"
                        font.pixelSize: 16
                        font.bold: true
                        color: errorColor
                    }
                    
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 16
                        rowSpacing: 8
                        
                        Label { text: "❌ 'Validation failed'"; font.bold: true; color: primaryTextColor; font.pixelSize: 12 }
                        Label { text: "Check partition file paths in JSON config"; color: secondaryTextColor; font.pixelSize: 11 }
                        
                        Label { text: "❌ 'Device won't boot'"; font.bold: true; color: primaryTextColor; font.pixelSize: 12 }
                        Label { text: "Flash with: fastboot --disable-verification flash vbmeta vbmeta.img"; color: secondaryTextColor; font.pixelSize: 11; font.family: "monospace" }
                        
                        Label { text: "❌ 'Size exceeds capacity'"; font.bold: true; color: primaryTextColor; font.pixelSize: 12 }
                        Label { text: "Shrink partitions with resize2fs or remove optional partitions"; color: secondaryTextColor; font.pixelSize: 11 }
                    }
                }
            }
            
            // Footer
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: accentColor
                radius: 8
                Layout.topMargin: 24
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    
                    Label {
                        text: "Zilium Super Compactor"
                        font.pixelSize: 18
                        font.bold: true
                        color: "#ffffff"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Label {
                        text: "Made with ❤️ by Badmaneers"
                        font.pixelSize: 13
                        color: "#e3f2fd"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Label {
                        text: "GitHub: github.com/Badmaneers/zilium"
                        font.pixelSize: 11
                        color: "#bbdefb"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
            
            // Bottom spacing
            Item { 
                Layout.fillWidth: true
                height: 20 
            }
        }
    }
}
