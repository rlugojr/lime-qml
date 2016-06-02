import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.0
import QtQuick.Dialogs 1.0
import QtQuick.Layouts 1.0
import QtGraphicalEffects 1.0

import "dialogs"

ApplicationWindow {
    id: window
    width: 800
    height: 600
    title: "Lime"

    property var myWindow
    property string themeFolder: "../../packages/Soda/Soda Dark"

    function view() {
      var tab = tabs.getTab(tabs.currentIndex);
       return tab === undefined ? undefined : tab.item;
    }

    function addTab(title, view) {
      var tab = tabs.addTab(title, tabTemplate);
      console.log("addTab", tab, tab.item);

      var loadTab = function() {
        tab.item.myView = view;
      }

      if (tab.item != null) {
        loadTab();
      } else {
        tab.loaded.connect(loadTab);
      }
      tab.active = true;
    }

    function activateTab(tabIndex) {
      tabs.currentIndex = tabIndex;
    }

    function removeTab(tabIndex) {
      tabs.removeTab(tabIndex);
    }

    function setTabTitle(tabIndex, title) {
      tabs.getTab(tabIndex).title = title;
    }

    menuBar: MenuBar {
        id: menu
        Menu {
            title: qsTr("File")
            MenuItem {
                text: qsTr("New File")
                onTriggered: frontend.runCommand("new_file");
            }
            MenuItem {
                text: qsTr("Open File...")
                onTriggered: openDialog.open();
            }
            MenuItem {
                text: qsTr("Save")
                onTriggered: frontend.runCommand("save");
            }
            MenuItem {
                text: qsTr("Save As...")
                // TODO(.) : qml doesn't have a ready dialog like FileDialog
                // onTriggered: saveAsDialog.open()
            }
            MenuItem {
                text: qsTr("Save All")
                onTriggered: frontend.runCommand("save_all")
            }
            MenuSeparator{}
            MenuItem {
                text: qsTr("New Window")
                onTriggered: frontend.runCommand("new_window");
            }
            MenuItem {
                text: qsTr("Close Window")
                onTriggered: frontend.runCommand("close_window");
            }
            MenuSeparator{}
            MenuItem {
                text: qsTr("Close File")
                onTriggered: frontend.runCommand("close");
            }
            MenuItem {
                text: qsTr("Close All Files")
                onTriggered: frontend.runCommand("close_all");
            }
            MenuSeparator{}
            MenuItem {
                text: qsTr("Quit")
                onTriggered: Qt.quit(); // frontend.runCommand("quit");
            }
        }
        Menu {
            title: qsTr("Find")
            MenuItem {
                text: qsTr("Find Next")
                onTriggered: frontend.runCommand("find_next");
            }
        }
        Menu {
            title: qsTr("Edit")
            MenuItem {
                text: qsTr("Undo")
                onTriggered: frontend.runCommand("undo");
            }
            MenuItem {
                text: qsTr("Redo")
                onTriggered: frontend.runCommand("redo");
            }
            Menu {
                title: qsTr("Undo Selection")
                MenuItem {
                    text: qsTr("Soft Undo")
                    onTriggered: frontend.runCommand("soft_undo");
                }
                MenuItem {
                    text: qsTr("Soft Redo")
                    onTriggered: frontend.runCommand("soft_redo");
                }
            }
            MenuSeparator{}
            MenuItem {
                text: qsTr("Copy")
                onTriggered: frontend.runCommand("copy");
            }
            MenuItem {
                text: qsTr("Cut")
                onTriggered: frontend.runCommand("cut");
            }
            MenuItem {
                text: qsTr("Paste")
                onTriggered: frontend.runCommand("paste");
            }
        }
        Menu {
            title: qsTr("View")
            MenuItem {
                text: qsTr("Show/Hide Console")
                onTriggered: { consoleView.visible = !consoleView.visible }
            }
            MenuItem {
                text: qsTr("Show/Hide Minimap")
                onTriggered: {
                  var tab = tabs.getTab(tabs.currentIndex);

                  if (tab.item)
                    tab.item.minimapVisible = !tab.item.minimapVisible;
                }
            }
            MenuItem {
                text: qsTr("Show/Hide Statusbar")
                onTriggered: { statusBar.visible = !statusBar.visible }
            }
        }
    }

    property Tab currentTab: tabs.count == 0? null : tabs.getTab(tabs.currentIndex)
    property var statusBarMap: currentTab == null || currentTab.item == null ? null : tabs.getTab(tabs.currentIndex).item.statusBar
    property var statusBarSorted: []
    onStatusBarMapChanged: {
      if (statusBarMap == null) {
        statusBarSorted = [];
        return;
      }

      console.log("status bar map:", statusBarMap);
      var keys = Object.keys(statusBarMap);
      keys.sort();
      console.log("status bar keys:", keys);
      var sorted = [];
      for (var i = 0; i < keys.length; i++)
        sorted.push(statusBarMap[keys[i]]);

      statusBarSorted = sorted;
    }


    statusBar: StatusBar {
        id: statusBar
        style: StatusBarStyle {
            background: Image {
              source: themeFolder + "/status-bar-background.png"
            }
        }

        property color textColor: "#969696"

        RowLayout {
            anchors.fill: parent
            id: statusBarRowLayout
            spacing: 15

            RowLayout {
                anchors.fill: parent
                spacing: 3
                Repeater {
                  model: statusBarSorted
                  delegate:
                    Label {
                        text: modelData
                        color: statusBar.textColor
                    }

                }
                Label {
                    text: "git branch: master"
                    color: statusBar.textColor
                }

                Label {
                    text: "INSERT MODE"
                    color: statusBar.textColor
                }

                Label {
                    id: statusBarCaretPos
                    text: "Line xx, Column yy"
                    color: statusBar.textColor
                }
            }

            Label {
                id: statusBarIndent
                text: "Tab Size/Spaces: 4"
                color: statusBar.textColor
                Layout.alignment: Qt.AlignRight
            }

            Label {
                id: statusBarLanguage
                text: "Go"
                color: statusBar.textColor
                Layout.alignment: Qt.AlignRight
            }
        }
    }

    Component {
      id: tabTemplate

      View {}
    }

    Item {
        anchors.fill: parent
        Keys.onPressed: {
          var v = view(); if (v === undefined) return;
          v.ctrl = (event.key == Qt.Key_Control) ? true : false;
          event.accepted = frontend.handleInput(event.text, event.key, event.modifiers)
          // if (event.key == Qt.Key_Alt)
          event.accepted = true;
        }
        Keys.onReleased: {
          var v = view(); if (v === undefined) return;
          v.ctrl = (event.key == Qt.Key_Control) ? false : view().ctrl;
        }
        focus: true // Focus required for Keys.onPressed
        SplitView {
            anchors.fill: parent
            orientation: Qt.Vertical
              TabView {
                Layout.fillHeight: true
                Layout.fillWidth: true
                id: tabs
                objectName: "tabs"
                style: TabViewStyle {
                    frameOverlap: 0
                    tab: Item {
                        implicitWidth: 180
                        implicitHeight: 28
                        ToolTip {
                            backgroundColor: "#BECCCC66"
                            textColor: "black"
                            font.pointSize: 8
                            text: (styleData.title != "") ? styleData.title : "untitled"
                            Component.onCompleted: {
                                this.parent = tabs;
                            }
                        }
                        BorderImage {
                            source: themeFolder + (styleData.selected ? "/tab-active.png" : "/tab-inactive.png")
                            border { left: 5; top: 5; right: 5; bottom: 5 }
                            width: 180
                            height: 25
                            Text {
                                id: tab_title
                                anchors.centerIn: parent
                                text: (styleData.title != "") ? styleData.title.replace(/^.*[\\\/]/, '') : "untitled"
                                color: frontend.defaultFg()
                                anchors.verticalCenterOffset: 1
                            }
                        }
                    }
                    tabBar: Image {
                        fillMode: Image.TileHorizontally
                        source: themeFolder + "/tabset-background.png"
                    }
                    tabsMovable: true
                    frame: Rectangle { color: frontend.defaultBg() }
                    tabOverlap: 5
                }

              }
              View {
                id: consoleView
                myView: frontend.console
                visible: false
                minimapVisible: false
                height: 100
              }
        }
    }
    OpenDialog {
        id: openDialog
    }
}
