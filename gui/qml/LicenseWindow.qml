import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import QtQuick.Window 2.15
import ZiliumGUI 1.0

Window {
    id: licenseWindow
    title: "Zilium License"
    width: 800
    height: 600
    minimumWidth: 600
    minimumHeight: 400
    
    flags: Qt.Window | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint
    
    property bool isDarkTheme: true
    property color backgroundColor: isDarkTheme ? "#232629" : "#fcfcfc"
    property color surfaceColor: isDarkTheme ? "#31363b" : "#ffffff"
    property color primaryTextColor: isDarkTheme ? "#eff0f1" : "#232629"
    property color secondaryTextColor: isDarkTheme ? "#bdc3c7" : "#6e6e6e"
    property color accentColor: "#3daee9"
    property color borderColor: isDarkTheme ? "#4d5254" : "#e0e0e0"
    
    Material.theme: isDarkTheme ? Material.Dark : Material.Light
    Material.primary: accentColor
    Material.accent: accentColor
    
    color: backgroundColor
    
    Component.onCompleted: {
        // Center window on screen
        x = Screen.width / 2 - width / 2
        y = Screen.height / 2 - height / 2
        // Load license
        licenseText.text = ziliumController.loadLicenseFile()
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0
        
        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: surfaceColor
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16
                
                Image {
                    source: "qrc:/ZiliumGUI/resources/zilium-logo.svg"
                    fillMode: Image.PreserveAspectFit
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    smooth: true
                }
                
                ColumnLayout {
                    spacing: 2
                    
                    Label {
                        text: "Zilium Super Compactor"
                        font.pixelSize: 18
                        font.bold: true
                        color: primaryTextColor
                    }
                    
                    Label {
                        text: "Version 1.0.0"
                        font.pixelSize: 12
                        color: secondaryTextColor
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                Label {
                    text: "Copyright © 2025 Badmaneers"
                    font.pixelSize: 11
                    color: secondaryTextColor
                }
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: borderColor
        }
        
        // Content
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            
            ColumnLayout {
                width: licenseWindow.width - 60
                spacing: 24
                
                Item { Layout.preferredHeight: 20 }
                
                // MIT License Section
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    spacing: 12
                    
                    Label {
                        text: "MIT License"
                        font.pixelSize: 20
                        font.bold: true
                        color: accentColor
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(300, Math.min(400, licenseText.implicitHeight + 32))
                        color: isDarkTheme ? "#1e1e1e" : "#f5f5f5"
                        radius: 8
                        border.color: borderColor
                        border.width: 1
                        
                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 16
                            clip: true
                            ScrollBar.vertical.policy: ScrollBar.AsNeeded
                            
                            Label {
                                id: licenseText
                                width: parent.width
                                text: "Loading license..."
                                wrapMode: Text.WordWrap
                                color: primaryTextColor
                                font.pixelSize: 12
                                font.family: "Consolas, Monaco, monospace"
                            }
                        }
                    }
                }
                
                // Third-Party Components Section
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    spacing: 12
                    
                    Label {
                        text: "Third-Party Components"
                        font.pixelSize: 18
                        font.bold: true
                        color: primaryTextColor
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: thirdPartyContent.implicitHeight + 24
                        color: isDarkTheme ? "#1e1e1e" : "#f5f5f5"
                        radius: 6
                        border.color: borderColor
                        border.width: 1
                        
                        ColumnLayout {
                            id: thirdPartyContent
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 10
                            
                            Label {
                                text: "This software includes the following open-source components:"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: secondaryTextColor
                                font.pixelSize: 12
                            }
                            
                            // Component items
                            Repeater {
                                model: [
                                    { name: "Qt6 Framework", author: "The Qt Company Ltd.", license: "LGPL v3 / GPL v3" },
                                    { name: "nlohmann/json", author: "Niels Lohmann", license: "MIT License" },
                                    { name: "Android LP Tools", author: "AOSP", license: "Apache 2.0 License" }
                                ]
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    Label {
                                        text: "• " + modelData.name
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: primaryTextColor
                                    }
                                    
                                    Label {
                                        text: "  " + modelData.author + " • " + modelData.license
                                        font.pixelSize: 11
                                        color: secondaryTextColor
                                        Layout.leftMargin: 4
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Source Code Link
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.preferredHeight: linkColumn.implicitHeight + 32
                    color: isDarkTheme ? "#1e1e1e" : "#f5f5f5"
                    radius: 6
                    border.color: borderColor
                    border.width: 1
                    
                    ColumnLayout {
                        id: linkColumn
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8
                        
                        Label {
                            text: "Source Code & Documentation"
                            font.pixelSize: 13
                            font.bold: true
                            color: primaryTextColor
                        }
                        
                        RowLayout {
                            spacing: 8
                            
                            Image {
                                source: "qrc:/ZiliumGUI/resources/github-icon.svg"
                                fillMode: Image.PreserveAspectFit
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                smooth: true
                            }
                            
                            Label {
                                text: '<a href="https://github.com/Badmaneers/zilium">github.com/Badmaneers/zilium</a>'
                                textFormat: Text.RichText
                                font.pixelSize: 12
                                color: accentColor
                                onLinkActivated: function(link) {
                                    Qt.openUrlExternally(link)
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.openUrlExternally("https://github.com/Badmaneers/zilium")
                                }
                            }
                        }
                    }
                }
                
                Item {
                    Layout.preferredHeight: 20
                }
            }
        }
    }
}
