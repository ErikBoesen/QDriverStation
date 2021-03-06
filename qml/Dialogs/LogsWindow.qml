/*
 * Copyright (c) 2015-2016 Alex Spataru <alex_spataru@outlook.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.4 as Controls
import Qt.labs.settings 1.0

import "../Widgets"
import "../Globals.js" as Globals

Window {
    id: window

    //
    // If this returns true, then this is the log of the current instance
    //
    property bool currentRun: selector.currentRow === 0

    //
    // Window size
    //
    width: minimumWidth
    height: minimumHeight
    minimumWidth: Globals.scale (820)
    minimumHeight: Globals.scale (420)

    //
    // Returns a list with the robot log names.
    // The list is reversed to put the latest logs on the top of the log
    // selector table.
    //
    function logs() {
        return DriverStation.availableLogs().reverse()
    }

    //
    // Opens the log at the given index
    //
    function openLog (index) {
        var correctedIndex = (logs().length - 1) - index
        DriverStation.openLog (DriverStation.logsPath()
                               + "/"
                               + DriverStation.availableLogs()[correctedIndex])
    }

    //
    // Updates the events charts and the console log to match the log file that
    // has been selected by the user.
    //
    function updateData() {
        var log = DriverStation.logVariant()

        // No logs, get out!
        if (logs().length <= 0)
            return

        //
        // Read log data, check Logger::saveFile() serialization code for more
        // information regarding the event registration order.
        //
        // Sorry for this, but I could not figure out how to register root keys
        // in the JSON document without breaking the rest of it...
        //
        var time              = log [0]
        var cpuUsge           = log [1]
        var ramUsge           = log [2]
        var pktLoss           = log [3]
        var voltage           = log [4]
        var codeStatus        = log [5]
        var controlMode       = log [6]
        var voltageStatus     = log [7]
        var enabledStatus     = log [8]
        var operationStatus   = log [9]
        var radioCommStatus   = log [10]
        var robotCommStatus   = log [11]
        var applicationOutput = log [12]
        var netConsoleMessage = log [13]

        //
        // We use this hack so that the app console behaves like a terminal
        // control (only if the log is from the running instance)
        //
        if (appConsole.text !== applicationOutput) {
            if (currentRun) {
                appConsole.text = ""
                appConsole.editor.append (applicationOutput)
            } else {
                appConsole.text = applicationOutput
            }
        }

        //
        // We use this hack so that the net console behaves like a terminal
        // control (only if the log is from the running instance)
        //
        if (netConsole.text !== netConsoleMessage) {
            if (currentRun) {
                netConsole.text = ""
                netConsole.editor.append (netConsoleMessage)
            } else {
                netConsole.text = netConsoleMessage
            }
        }

        //
        // Change window title
        //
        window.title = qsTr ("QDriverStation Log Viewer (%1 seconds)").arg (time / 1000)
    }

    //
    // Default window position
    //
    x: (Screen.width - width) / 4
    y: (Screen.height - height) / 4

    //
    // Window properties
    //
    visible: false
    color: Globals.Colors.WindowBackground
    title: qsTr ("QDriverStation Log File Viewer")

    //
    // Show latest log on init
    //
    onVisibleChanged: {
        if (visible)
            selector.currentRow = 0
    }

    //
    // Save settings
    //
    Settings {
        category: "Logs Window"
        property alias x: window.x
        property alias y: window.y
        property alias width: window.width
        property alias height: window.height
    }

    //
    // Update the displayed data when user selects another log file
    //
    Connections {
        target: DriverStation
        onLogFileChanged: updateData()
    }

    //
    // Main layout
    //
    RowLayout {
        anchors.fill: parent
        spacing: Globals.spacing
        anchors.margins: Globals.spacing

        //
        // Navigator bar
        //
        ColumnLayout {
            Layout.fillWidth: false
            Layout.fillHeight: true
            spacing: Globals.spacing

            //
            // Choose log file caption & button
            //
            RowLayout {
                Label {
                    Layout.fillWidth: true
                    text: qsTr ("Choose log file") + ": "
                    anchors.verticalCenter: parent.verticalCenter
                }

                Button {
                    width: 2 * height
                    icon: icons.fa_folder_open_o
                    onClicked: {
                        openLog (1)
                        selector.currentRow = 1
                        DriverStation.browseLogs()
                    }

                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            //
            // Log selector
            //
            Controls.TableView {
                id: selector
                model: logs()
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: Globals.scale (220)
                onCurrentRowChanged: openLog (currentRow)

                Controls.TableViewColumn {
                    role: ""
                    title: qsTr ("Log Name")
                }
            }
        }

        //
        // Log display controls
        //
        Panel {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: Globals.spacing
                anchors.margins: Globals.spacing

                //
                // Log type selector
                //
                RowLayout {
                    Layout.fillWidth: true

                    Button {
                        caption.font.bold: true
                        baseColor: currentRun ? "#B9262E" : "#630008"
                        text: currentRun ? qsTr ("Live Feed") :
                                           qsTr ("Past Feed")
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        id: evnBt
                        checked: true
                        text: qsTr ("Event Chart")

                        onClicked: {
                            evnBt.checked = true
                            appBt.checked = false
                            netBt.checked = false
                            evnPlot.visible = true
                            netLogs.visible = false
                            appLogs.visible = false
                        }
                    }

                    Button {
                        id: appBt
                        text: qsTr ("App Logs")

                        onClicked: {
                            appBt.checked = true
                            netBt.checked = false
                            evnBt.checked = false
                            appLogs.visible = true
                            netLogs.visible = false
                            evnPlot.visible = false
                        }
                    }

                    Button {
                        id: netBt
                        text: qsTr ("NetConsole")

                        onClicked: {
                            netBt.checked = true
                            evnBt.checked = false
                            appBt.checked = false
                            netLogs.visible = true
                            appLogs.visible = false
                            evnPlot.visible = false
                        }
                    }
                }

                //
                // Event charts
                //
                RowLayout {
                    id: evnPlot
                    visible: true
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Globals.spacing

                    //
                    // Colors
                    //
                    property string pktColor: "#001942"
                    property string cpuColor: "#B9262E"
                    property string ramColor: "#FF9923"
                    property string volColor: "#81ACB5"

                    //
                    // Plot (this will be a pain in the ass)
                    //
                    Plot {
                        id: plot
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Label {
                            size: large
                            anchors.centerIn: parent
                            text: qsTr ("Coming soon") + "..."
                        }
                    }

                    //
                    // Graph legends
                    //
                    ColumnLayout {
                        Layout.fillWidth: false
                        Layout.fillHeight: true
                        spacing: Globals.spacing

                        LED {
                            text: qsTr ("Lost Packets")
                            unpoweredColor: evnPlot.pktColor
                        }

                        LED {
                            text: qsTr ("CPU") + " %"
                            unpoweredColor: evnPlot.cpuColor
                        }

                        LED {
                            text: qsTr ("RAM") + " %"
                            unpoweredColor: evnPlot.ramColor
                        }

                        LED {
                            text: qsTr ("Voltage") + " %"
                            unpoweredColor: evnPlot.volColor
                        }
                    }
                }

                //
                // Console logs
                //
                ColumnLayout {
                    id: appLogs
                    visible: false
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextEditor {
                        id: appConsole
                        editor.readOnly: true
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        editor.textFormat: Text.PlainText
                        editor.font.family: Globals.monoFont
                        editor.font.pixelSize: Globals.scale (13)
                        foregroundColor: Globals.Colors.WidgetForeground
                        backgroundColor: Globals.Colors.WindowBackground
                    }

                    Button {
                        icon: icons.fa_copy
                        width: Globals.scale (48)
                        height: Globals.scale (24)
                        iconSize: Globals.scale (12)

                        onClicked: {
                            appConsole.copy()
                            appConsole.editor.append (qsTr ("Console output copied to clipboard"))
                        }
                    }
                }

                //
                // NetConsole logs
                //
                ColumnLayout {
                    id: netLogs
                    visible: false
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextEditor {
                        id: netConsole
                        editor.readOnly: true
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        editor.textFormat: Text.PlainText
                        editor.font.family: Globals.monoFont
                        editor.font.pixelSize: Globals.scale (13)
                        foregroundColor: Globals.Colors.WidgetForeground
                        backgroundColor: Globals.Colors.WindowBackground
                    }

                    Button {
                        icon: icons.fa_copy
                        width: Globals.scale (48)
                        height: Globals.scale (24)
                        iconSize: Globals.scale (12)

                        onClicked: {
                            netConsole.copy()
                            netConsole.editor.append (qsTr ("NetConsole output copied to clipboard"))
                        }
                    }
                }
            }
        }
    }
}
