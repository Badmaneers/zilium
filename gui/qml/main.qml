import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import ZiliumGUI 1.0

ApplicationWindow {
    id: window
    
    // Window properties
    title: "Zilium Super Compactor"
    width: 1280
    height: 720
    minimumWidth: 1000
    minimumHeight: 600
    visible: true
    
    // Theme properties
    property bool isDarkTheme: true
    property color backgroundColor: isDarkTheme ? "#232629" : "#fcfcfc"
    property color surfaceColor: isDarkTheme ? "#31363b" : "#ffffff"
    property color primaryTextColor: isDarkTheme ? "#eff0f1" : "#232629"
    property color secondaryTextColor: isDarkTheme ? "#bdc3c7" : "#6e6e6e"
    property color accentColor: "#3daee9"
    property color borderColor: isDarkTheme ? "#4d5254" : "#e0e0e0"
    property color buttonColor: isDarkTheme ? "#31363b" : "#f5f5f5"
    property color buttonHoverColor: isDarkTheme ? "#3c4245" : "#eeeeee"
    property color consoleBackground: isDarkTheme ? "#1e1e1e" : "#fafafa"
    
    // Material theme
    Material.theme: isDarkTheme ? Material.Dark : Material.Light
    Material.primary: accentColor
    Material.accent: accentColor
    Material.background: backgroundColor
    Material.foreground: primaryTextColor
    
    // Background with blur effect
    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        opacity: 0.95
    }
    
    // Custom header
    header: Rectangle {
        height: 48
        color: surfaceColor
        border.color: borderColor
        border.width: 1
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            
            // Logo
            Image {
                source: "qrc:/ZiliumGUI/resources/zilium-logo.svg"
                fillMode: Image.PreserveAspectFit
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                smooth: true
            }
            
            // Title
            Label {
                text: "Zilium Super Compactor"
                font.pixelSize: 16
                font.bold: true
                color: primaryTextColor
                Layout.fillWidth: true
            }
        }
    }
    
    // Main content
    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
        
        // Left Panel (Workflow Area)
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: window.width * 0.6
            color: surfaceColor
            border.color: borderColor
            border.width: 1
            radius: 4
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16
                
                // Input/Output Section
                GroupBox {
                    title: "Configuration"
                    Layout.fillWidth: true
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8
                        
                        // JSON file selection
                        Label {
                            text: "Select .json file"
                            color: primaryTextColor
                            font.pixelSize: 12
                        }
                        
                        RowLayout {
                            TextField {
                                id: configPathField
                                placeholderText: ziliumController.configPath === "" ? "/path/to/config.json" : ""
                                text: ziliumController.configPath
                                Layout.fillWidth: true
                                color: primaryTextColor
                                readOnly: true
                                
                                background: Rectangle {
                                    color: backgroundColor
                                    border.color: borderColor
                                    border.width: 1
                                    radius: 2
                                }
                            }
                            
                            Button {
                                text: "Browse..."
                                Material.background: buttonColor
                                
                                onClicked: {
                                    console.log("Browse for config clicked")
                                    ziliumController.browseForConfig()
                                }
                            }
                        }
                        
                        // Output folder selection
                        Label {
                            text: "Select Output folder"
                            color: primaryTextColor
                            font.pixelSize: 12
                        }
                        
                        RowLayout {
                            TextField {
                                id: outputPathField
                                placeholderText: ziliumController.outputPath === "" ? "/path/to/output/" : ""
                                text: ziliumController.outputPath
                                Layout.fillWidth: true
                                color: primaryTextColor
                                readOnly: true
                                
                                background: Rectangle {
                                    color: backgroundColor
                                    border.color: borderColor
                                    border.width: 1
                                    radius: 2
                                }
                            }
                            
                            Button {
                                text: "Browse..."
                                Material.background: buttonColor
                                
                                onClicked: {
                                    console.log("Browse for output clicked")
                                    ziliumController.browseForOutput()
                                }
                            }
                        }
                    }
                }
                
                // Console Output Section
                GroupBox {
                    title: "Console Log"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4
                        
                        ScrollView {
                            id: consoleScrollView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.topMargin: 8
                            clip: true
                            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            
                            TextArea {
                                id: consoleLog
                                readOnly: true
                                text: ziliumController.consoleOutput
                                wrapMode: TextArea.Wrap
                                selectByMouse: true
                                color: primaryTextColor
                                font.family: "Consolas, Monaco, monospace"
                                font.pixelSize: 11
                                leftPadding: 12
                                rightPadding: 12
                                topPadding: 16
                                bottomPadding: 12
                                
                                background: Rectangle {
                                    color: consoleBackground
                                    border.color: borderColor
                                    border.width: 1
                                    radius: 2
                                }
                                
                                // Auto-scroll to bottom when text changes
                                onTextChanged: {
                                    Qt.callLater(function() {
                                        consoleScrollView.ScrollBar.vertical.position = 1.0 - consoleScrollView.ScrollBar.vertical.size
                                    })
                                }
                            }
                        }
                    }
                }
                
                // Status and Progress Section
                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: "Status: " + ziliumController.status
                        color: primaryTextColor
                        font.pixelSize: 12
                    }
                    
                    ProgressBar {
                        Layout.fillWidth: true
                        value: ziliumController.progress / 100.0
                        Material.accent: accentColor
                    }
                    
                    Label {
                        text: ziliumController.progress + "%"
                        color: secondaryTextColor
                        font.pixelSize: 10
                    }
                }
                
                // Verify Output Button (shown after successful build)
                Button {
                    text: "Verify Output Image"
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(32, window.height * 0.045)
                    Layout.maximumHeight: 44
                    font.pixelSize: Math.max(11, Math.min(14, window.width * 0.009))
                    Material.background: "#4caf50"
                    Material.foreground: "white"
                    visible: ziliumController.status === "Success" && !ziliumController.isRunning
                    
                    onClicked: {
                        console.log("Verify output clicked")
                        ziliumController.verifyOutputImage()
                    }
                }
            }
        }
        
        // Right Panel (Information & Configuration)
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: surfaceColor
            border.color: borderColor
            border.width: 1
            radius: 4
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                
                TabBar {
                    id: tabBar
                    Layout.fillWidth: true
                    Material.background: backgroundColor
                    
                    TabButton {
                        text: "Super Info"
                        Material.foreground: primaryTextColor
                    }
                    TabButton {
                        text: "Partitions"
                        Material.foreground: primaryTextColor
                    }
                    TabButton {
                        text: "Settings"
                        Material.foreground: primaryTextColor
                    }
                    TabButton {
                        text: "Developer Info"
                        Material.foreground: primaryTextColor
                    }
                }
                
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: tabBar.currentIndex
                    
                    // Tab 1: Super Info
                    Item {
                        visible: tabBar.currentIndex === 0
                        anchors.fill: parent
                        
                        GridLayout {
                            columns: 2
                            columnSpacing: 16
                            rowSpacing: 6
                            anchors.fill: parent
                            anchors.margins: 12
                            
                            Label {
                                text: "Device Slot Type:"
                                color: primaryTextColor
                                font.bold: true
                            }
                            TextField {
                                text: configModel.deviceSlotType
                                readOnly: true
                                Layout.fillWidth: true
                                color: primaryTextColor
                                background: Rectangle {
                                    color: backgroundColor
                                    border.color: borderColor
                                    border.width: 1
                                    radius: 2
                                }
                            }
                            
                            Label {
                                text: "Block Size:"
                                color: primaryTextColor
                                font.bold: true
                            }
                            TextField {
                                text: configModel.blockSize + " bytes"
                                readOnly: true
                                Layout.fillWidth: true
                                color: primaryTextColor
                                background: Rectangle {
                                    color: backgroundColor
                                    border.color: borderColor
                                    border.width: 1
                                    radius: 2
                                }
                            }
                            
                            Label {
                                text: "Super Partition Name:"
                                color: primaryTextColor
                                font.bold: true
                            }
                            TextField {
                                text: configModel.superPartitionName
                                readOnly: true
                                Layout.fillWidth: true
                                color: primaryTextColor
                                background: Rectangle {
                                    color: backgroundColor
                                    border.color: borderColor
                                    border.width: 1
                                    radius: 2
                                }
                            }
                            
                            Label {
                                text: "Total Size:"
                                color: primaryTextColor
                                font.bold: true
                            }
                            TextField {
                                text: configModel.totalSize
                                readOnly: true
                                Layout.fillWidth: true
                                color: primaryTextColor
                                background: Rectangle {
                                    color: backgroundColor
                                    border.color: borderColor
                                    border.width: 1
                                    radius: 2
                                }
                            }
                            
                            Label {
                                text: "Metadata Version:"
                                color: primaryTextColor
                                font.bold: true
                            }
                            TextField {
                                text: configModel.metadataversion
                                readOnly: true
                                Layout.fillWidth: true
                                color: primaryTextColor
                                background: Rectangle {
                                    color: backgroundColor
                                    border.color: borderColor
                                    border.width: 1
                                    radius: 2
                                }
                            }
                            
                            Label {
                                text: "Metadata Size:"
                                color: primaryTextColor
                                font.bold: true
                            }
                            TextField {
                                text: configModel.metadataSize + " bytes"
                                readOnly: true
                                Layout.fillWidth: true
                                color: primaryTextColor
                                background: Rectangle {
                                    color: backgroundColor
                                    border.color: borderColor
                                    border.width: 1
                                    radius: 2
                                }
                            }
                            
                            Label {
                                text: "Max Super Size:"
                                color: primaryTextColor
                                font.bold: true
                            }
                            TextField {
                                text: configModel.maxSizeOfSuper
                                readOnly: true
                                Layout.fillWidth: true
                                color: primaryTextColor
                                background: Rectangle {
                                    color: backgroundColor
                                    border.color: borderColor
                                    border.width: 1
                                    radius: 2
                                }
                            }
                            
                            Label {
                                text: "Alignment:"
                                color: primaryTextColor
                                font.bold: true
                            }
                            TextField {
                                text: configModel.alignment
                                readOnly: true
                                Layout.fillWidth: true
                                color: primaryTextColor
                                background: Rectangle {
                                    color: backgroundColor
                                    border.color: borderColor
                                    border.width: 1
                                    radius: 2
                                }
                            }
                            
                            Label {
                                text: "Alignment Offset:"
                                color: primaryTextColor
                                font.bold: true
                            }
                            TextField {
                                text: configModel.alignmentOffset + " bytes"
                                readOnly: true
                                Layout.fillWidth: true
                                color: primaryTextColor
                                background: Rectangle {
                                    color: backgroundColor
                                    border.color: borderColor
                                    border.width: 1
                                    radius: 2
                                }
                            }
                            
                            Label {
                                text: "Number of Partitions:"
                                color: primaryTextColor
                                font.bold: true
                            }
                            TextField {
                                text: configModel.partitionCount.toString()
                                readOnly: true
                                Layout.fillWidth: true
                                color: primaryTextColor
                                background: Rectangle {
                                    color: backgroundColor
                                    border.color: borderColor
                                    border.width: 1
                                    radius: 2
                                }
                            }
                            
                            // Validation Status Section
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.columnSpan: 2
                                Layout.topMargin: 16
                                height: 1
                                color: borderColor
                            }
                            
                            Label {
                                text: "Validation Status"
                                Layout.columnSpan: 2
                                color: primaryTextColor
                                font.bold: true
                                font.pixelSize: 14
                            }
                            
                            RowLayout {
                                Layout.columnSpan: 2
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 16
                                
                                // Validation info box - takes most of the space
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: parent.width * 0.85
                                    spacing: 8
                                    
                                    // Overall status
                                    RowLayout {
                                        Layout.fillWidth: true
                                        
                                        Label {
                                            text: {
                                                if (ziliumController.configPath === "") {
                                                    return "⚬ No Configuration Loaded"
                                                }
                                                return ziliumController.isValid ? "✓ Configuration Valid" : "✗ Configuration Invalid"
                                            }
                                            color: {
                                                if (ziliumController.configPath === "") {
                                                    return secondaryTextColor
                                                }
                                                return ziliumController.isValid ? "#4caf50" : "#f44336"
                                            }
                                            font.bold: true
                                            font.pixelSize: 13
                                        }
                                        
                                        Item { Layout.fillWidth: true }
                                        
                                        Label {
                                            text: "Estimated time: " + (ziliumController.configPath === "" ? "N/A" : ziliumController.estimatedTime)
                                            color: secondaryTextColor
                                            font.pixelSize: 11
                                        }
                                    }
                                    
                                    // Scrollable area for errors and warnings
                                    ScrollView {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.topMargin: 8
                                        clip: true
                                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                                        
                                        TextArea {
                                            id: validationText
                                            readOnly: true
                                            selectByMouse: true
                                            wrapMode: TextArea.Wrap
                                            font.family: "Consolas, Monaco, monospace"
                                            font.pixelSize: 11
                                            leftPadding: 12
                                            rightPadding: 12
                                            topPadding: 16
                                            bottomPadding: 12
                                            
                                            background: Rectangle {
                                                color: consoleBackground
                                                border.color: borderColor
                                                border.width: 1
                                                radius: 2
                                            }
                                            
                                            text: {
                                                // Check if configuration is loaded
                                                if (ziliumController.configPath === "") {
                                                    return "No configuration loaded.\n\nPlease select a .json configuration file to begin."
                                                }
                                                
                                                var result = ""
                                                
                                                // Add errors
                                                if (ziliumController.validationErrors.length > 0) {
                                                    result += "Errors:\n"
                                                    for (var i = 0; i < ziliumController.validationErrors.length; i++) {
                                                        result += "  ✗ " + ziliumController.validationErrors[i] + "\n"
                                                    }
                                                    result += "\n"
                                                }
                                                
                                                // Add warnings
                                                if (ziliumController.validationWarnings.length > 0) {
                                                    result += "Warnings:\n"
                                                    for (var j = 0; j < ziliumController.validationWarnings.length; j++) {
                                                        result += "  ⚠ " + ziliumController.validationWarnings[j] + "\n"
                                                    }
                                                }
                                                
                                                // If no errors or warnings but config is loaded
                                                if (result === "" && ziliumController.configPath !== "") {
                                                    result = "No validation issues detected.\n\nConfiguration is ready for compilation."
                                                }
                                                
                                                return result
                                            }
                                            
                                            color: primaryTextColor
                                        }
                                    }
                                }
                                
                                // Spacer to push buttons to the right
                                Item {
                                    Layout.fillWidth: true
                                }
                                
                                // Action buttons column on the far right
                                ColumnLayout {
                                    Layout.preferredWidth: Math.max(100, window.width * 0.08)
                                    Layout.maximumWidth: 150
                                    Layout.alignment: Qt.AlignRight
                                    spacing: 8
                                    
                                    // Save button (only enabled when changes made)
                                    Button {
                                        text: "💾\nSave"
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: Math.max(60, window.height * 0.08)
                                        Material.background: "#4caf50"
                                        Material.foreground: "white"
                                        font.pixelSize: Math.max(9, Math.min(12, window.width * 0.008))
                                        font.bold: true
                                        enabled: ziliumController.hasUnsavedChanges
                                        
                                        ToolTip.visible: hovered
                                        ToolTip.text: ziliumController.hasUnsavedChanges ? 
                                            "Save configuration to custom location" :
                                            "No changes to save"
                                        
                                        onClicked: {
                                            var savedPath = ziliumController.saveConfigAs()
                                            if (savedPath !== "") {
                                                console.log("Configuration saved to:", savedPath)
                                            }
                                        }
                                    }
                                    
                                    // Validate button
                                    Button {
                                        text: "🔍\nRe-validate"
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: Math.max(60, window.height * 0.08)
                                        Material.background: buttonColor
                                        font.pixelSize: Math.max(9, Math.min(12, window.width * 0.008))
                                        
                                        ToolTip.visible: hovered
                                        ToolTip.text: "Re-validate configuration"
                                        
                                        onClicked: {
                                            ziliumController.validateConfiguration()
                                        }
                                    }
                                    
                                    // Start/Stop Compiling button
                                    Button {
                                        text: ziliumController.isRunning ? "⏹\nStop" : "▶\nStart"
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: Math.max(60, window.height * 0.08)
                                        Material.background: ziliumController.isRunning ? "#f44336" : accentColor
                                        Material.foreground: "white"
                                        font.pixelSize: Math.max(9, Math.min(12, window.width * 0.008))
                                        font.bold: true
                                        enabled: ziliumController.isRunning || (ziliumController.isValid && !ziliumController.hasUnsavedChanges && ziliumController.configPath !== "" && ziliumController.outputPath !== "")
                                        
                                        ToolTip.visible: hovered && !enabled && !ziliumController.isRunning
                                        ToolTip.text: ziliumController.configPath === "" ? "Please select a configuration file" : 
                                                      ziliumController.outputPath === "" ? "Please select an output directory" : 
                                                      !ziliumController.isValid ? "Configuration validation failed - check errors in validation section" :
                                                      ziliumController.hasUnsavedChanges ? "Please save your configuration changes first" : ""
                                        
                                        onClicked: {
                                            if (ziliumController.isRunning) {
                                                console.log("Stop compiling clicked")
                                                ziliumController.stopCompiling()
                                            } else {
                                                console.log("Start compiling clicked")
                                                ziliumController.startCompiling()
                                            }
                                        }
                                    }
                                    
                                    // Clear Log button
                                    Button {
                                        text: "🗑️\nClear Log"
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: Math.max(60, window.height * 0.08)
                                        Material.background: buttonColor
                                        font.pixelSize: Math.max(9, Math.min(12, window.width * 0.008))
                                        
                                        ToolTip.visible: hovered
                                        ToolTip.text: "Clear console log"
                                        
                                        onClicked: {
                                            console.log("Clear log clicked")
                                            ziliumController.clearConsole()
                                        }
                                    }
                                    
                                    Item { Layout.fillHeight: true }
                                }
                            }
                        }
                    }
                    
                    // Tab 2: Partitions
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4
                        visible: tabBar.currentIndex === 1
                        
                        HorizontalHeaderView {
                            id: horizontalHeader
                            syncView: partitionTableView
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            
                            delegate: Rectangle {
                                color: buttonColor
                                border.color: borderColor
                                border.width: 1
                                implicitHeight: 32
                                
                                Label {
                                    anchors.centerIn: parent
                                    text: {
                                        switch(column) {
                                            case 0: return "☑"
                                            case 1: return "Partition"
                                            case 2: return "Size"
                                            case 3: return "Image Path"
                                            default: return ""
                                        }
                                    }
                                    font.bold: true
                                    color: primaryTextColor
                                    font.pixelSize: 12
                                }
                            }
                        }
                        
                        TableView {
                            id: partitionTableView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: partitionModel
                            clip: true
                            columnSpacing: 1
                            rowSpacing: 1
                            
                            // Set column widths
                            columnWidthProvider: function(column) {
                                switch(column) {
                                    case 0: return 50   // Enabled - checkbox
                                    case 1: return 150  // Name
                                    case 2: return 100  // Size
                                    case 3: return partitionTableView.width - 310  // Path - remaining space
                                    default: return 100
                                }
                            }
                            
                            delegate: Rectangle {
                                implicitHeight: 36
                                color: row % 2 === 0 ? backgroundColor : surfaceColor
                                border.color: borderColor
                                border.width: 0.5
                                
                                Item {
                                    anchors.fill: parent
                                    
                                    // Column 0: Checkbox for enabled/disabled
                                    CheckBox {
                                        visible: column === 0
                                        anchors.centerIn: parent
                                        checked: model.enabled
                                        Material.accent: accentColor
                                        
                                        onClicked: {
                                            partitionModel.setPartitionEnabled(row, checked)
                                        }
                                    }
                                    
                                    // Columns 1-2: Read-only labels
                                    Label {
                                        visible: column === 1 || column === 2
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        verticalAlignment: Text.AlignVCenter
                                        text: {
                                            switch(column) {
                                                case 1: return model.name || ""
                                                case 2: return model.size || ""
                                                default: return ""
                                            }
                                        }
                                        color: primaryTextColor
                                        elide: Text.ElideRight
                                        font.pixelSize: 11
                                    }
                                    
                                    // Column 3: Editable path with browse button
                                    RowLayout {
                                        visible: column === 3
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        spacing: 2
                                        
                                        TextField {
                                            text: model.path || ""
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            color: primaryTextColor
                                            font.pixelSize: 9
                                            padding: 4
                                            
                                            background: Rectangle {
                                                color: "transparent"
                                                border.color: borderColor
                                                border.width: 1
                                                radius: 2
                                            }
                                            
                                            onEditingFinished: {
                                                partitionModel.setPartitionPath(row, text)
                                            }
                                        }
                                        
                                        // Browse button
                                        Button {
                                            text: "…"  // Unicode ellipsis
                                            font.pixelSize: 20
                                            font.bold: true
                                            Layout.preferredWidth: 40
                                            Layout.preferredHeight: 30
                                            padding: 0
                                            Material.background: buttonColor
                                            Material.elevation: 2
                                            
                                            contentItem: Text {
                                                text: "…"
                                                font: parent.font
                                                color: primaryTextColor
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            
                                            onClicked: {
                                                console.log("Browse button clicked for row:", row)
                                                partitionModel.browseForPartitionImage(row)
                                            }
                                            
                                            ToolTip.visible: hovered
                                            ToolTip.text: "Browse for custom image"
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Tab 3: Settings
                    Item {
                        visible: tabBar.currentIndex === 2
                        anchors.fill: parent
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 24
                            spacing: 16
                            
                            // Appearance Section
                            Label {
                                text: "Appearance"
                                font.pixelSize: 16
                                font.bold: true
                                color: primaryTextColor
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: borderColor
                            }
                            
                                                        // Theme Toggle
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                
                                Label {
                                    text: "💡"
                                    font.pixelSize: 24
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    Label {
                                        text: "Theme"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: primaryTextColor
                                    }
                                    
                                    Label {
                                        text: "Switch between light and dark mode"
                                        font.pixelSize: 11
                                        color: secondaryTextColor
                                    }
                                }
                                
                                Switch {
                                    checked: isDarkTheme
                                    onToggled: {
                                        isDarkTheme = checked
                                        console.log("Theme toggled:", isDarkTheme ? "Dark" : "Light")
                                    }
                                }
                                
                                Label {
                                    text: isDarkTheme ? "Dark" : "Light"
                                    font.pixelSize: 12
                                    color: secondaryTextColor
                                    Layout.preferredWidth: 45
                                }
                            }
                            
                            Item { Layout.preferredHeight: 8 }
                            
                            // Help & Information Section
                            Label {
                                text: "Help & Information"
                                font.pixelSize: 16
                                font.bold: true
                                color: primaryTextColor
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: borderColor
                            }
                            
                            // Quick Guide Button
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                
                                Label {
                                    text: "📖"
                                    font.pixelSize: 24
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    Label {
                                        text: "Quick Guide"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: primaryTextColor
                                    }
                                    
                                    Label {
                                        text: "View usage guide for GUI and CLI"
                                        font.pixelSize: 11
                                        color: secondaryTextColor
                                    }
                                }
                                
                                Button {
                                    text: "Show Guide"
                                    Material.background: accentColor
                                    Material.foreground: "white"
                                    font.pixelSize: 11
                                    
                                    onClicked: {
                                        guideWindow.show()
                                    }
                                }
                            }
                            
                            // License Button
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                
                                Label {
                                    text: "⚖️"
                                    font.pixelSize: 24
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    Label {
                                        text: "License"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: primaryTextColor
                                    }
                                    
                                    Label {
                                        text: "View MIT License information"
                                        font.pixelSize: 11
                                        color: secondaryTextColor
                                    }
                                }
                                
                                Button {
                                    text: "Show License"
                                    Material.background: buttonColor
                                    font.pixelSize: 11
                                    
                                    onClicked: {
                                        licenseWindow.show()
                                        licenseWindow.raise()
                                        licenseWindow.requestActivate()
                                    }
                                }
                            }
                            
                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }
                    
                    // Tab 4: Developer Info
                    Item {
                        visible: tabBar.currentIndex === 3
                        anchors.fill: parent
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12
                            
                            // Logo and Title
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 10
                                
                                Image {
                                    source: "qrc:/ZiliumGUI/resources/zilium-logo.svg"
                                    fillMode: Image.PreserveAspectFit
                                    Layout.preferredWidth: 48
                                    Layout.preferredHeight: 48
                                    smooth: true
                                }
                                
                                Label {
                                    text: "Zilium Super Compactor"
                                    font.pixelSize: 20
                                    font.bold: true
                                    color: primaryTextColor
                                }
                            }
                            
                            Label {
                                text: "Version: 1.0.0"
                                color: secondaryTextColor
                                font.pixelSize: 12
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: borderColor
                            }
                            
                            Label {
                                text: "A powerful tool for rebuilding and compacting super partition images for Realme/OPPO/OnePlus devices with stock vbmeta compatibility."
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: primaryTextColor
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }
                            
                            Item { Layout.preferredHeight: 8 }
                            
                            Label {
                                text: "Features:"
                                font.bold: true
                                font.pixelSize: 13
                                color: primaryTextColor
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            GridLayout {
                                columns: 2
                                columnSpacing: 20
                                rowSpacing: 6
                                Layout.alignment: Qt.AlignHCenter
                                
                                Label {
                                    text: "• Stock VBMeta Compatible"
                                    color: secondaryTextColor
                                    font.pixelSize: 11
                                }
                                Label {
                                    text: "• A/B & Non-A/B Support"
                                    color: secondaryTextColor
                                    font.pixelSize: 11
                                }
                                Label {
                                    text: "• Self-Contained"
                                    color: secondaryTextColor
                                    font.pixelSize: 11
                                }
                                Label {
                                    text: "• Fast Builds"
                                    color: secondaryTextColor
                                    font.pixelSize: 11
                                }
                            }
                            
                            Item { Layout.fillHeight: true }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: borderColor
                            }
                            
                            // Social Links
                            ColumnLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 8
                                
                                // Telegram Link
                                RowLayout {
                                    spacing: 8
                                    Layout.alignment: Qt.AlignHCenter
                                    
                                    Image {
                                        source: "qrc:/ZiliumGUI/resources/telegram-icon.svg"
                                        fillMode: Image.PreserveAspectFit
                                        Layout.preferredWidth: 20
                                        Layout.preferredHeight: 20
                                        smooth: true
                                    }
                                    
                                    Label {
                                        text: "Telegram: @DumbDragon"
                                        color: secondaryTextColor
                                        font.pixelSize: 12
                                    }
                                    
                                    Button {
                                        text: "Open"
                                        flat: true
                                        Material.foreground: accentColor
                                        font.pixelSize: 10
                                        onClicked: Qt.openUrlExternally("https://t.me/DumbDragon")
                                    }
                                }
                                
                                // GitHub Link
                                RowLayout {
                                    spacing: 8
                                    Layout.alignment: Qt.AlignHCenter
                                    
                                    Image {
                                        source: "qrc:/ZiliumGUI/resources/github-icon.svg"
                                        fillMode: Image.PreserveAspectFit
                                        Layout.preferredWidth: 20
                                        Layout.preferredHeight: 20
                                        smooth: true
                                    }
                                    
                                    Label {
                                        text: "GitHub: Badmaneers"
                                        color: secondaryTextColor
                                        font.pixelSize: 12
                                    }
                                    
                                    Button {
                                        text: "Open"
                                        flat: true
                                        Material.foreground: accentColor
                                        font.pixelSize: 10
                                        onClicked: Qt.openUrlExternally("https://github.com/Badmaneers")
                                    }
                                }
                            }
                            
                            Item { Layout.preferredHeight: 8 }
                            
                            Label {
                                text: "Created by Badmaneers"
                                color: secondaryTextColor
                                font.pixelSize: 11
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Guide Window (separate window)
    GuideDialog {
        id: guideWindow
    }
    
    // License Window (separate window)
    LicenseWindow {
        id: licenseWindow
    }
    
    // Footer
    footer: Rectangle {
        height: 24
        color: surfaceColor
        border.color: borderColor
        border.width: 1
        
        Label {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "v1.0"
            color: secondaryTextColor
            font.pixelSize: 10
        }
    }
}
