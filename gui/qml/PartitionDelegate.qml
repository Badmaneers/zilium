import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    property bool isEnabled: true
    property string partitionName: ""
    property string partitionSize: ""
    property string partitionPath: ""
    
    implicitHeight: 40
    color: index % 2 === 0 ? "#31363b" : "#232629"
    border.color: "#4d5254"
    border.width: 0.5
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
        
        CheckBox {
            id: enabledCheckBox
            checked: root.isEnabled
            Layout.preferredWidth: 32
            
            onCheckedChanged: {
                root.isEnabled = checked
            }
        }
        
        Label {
            text: root.partitionName
            color: "#eff0f1"
            Layout.preferredWidth: 100
            elide: Text.ElideRight
        }
        
        Label {
            text: root.partitionSize
            color: "#bdc3c7"
            Layout.preferredWidth: 80
            elide: Text.ElideRight
        }
        
        Label {
            text: root.partitionPath
            color: "#bdc3c7"
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }
}
