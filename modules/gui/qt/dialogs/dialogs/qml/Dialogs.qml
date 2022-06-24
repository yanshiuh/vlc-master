/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.0
import org.videolan.vlc 0.1


import "qrc:///widgets/" as Widgets
import "qrc:///style/"

Item {
    id: root

    //---------------------------------------------------------------------------------------------
    // Properties
    //---------------------------------------------------------------------------------------------

    property Item bgContent: null

    //---------------------------------------------------------------------------------------------
    // Signal
    //---------------------------------------------------------------------------------------------

    signal restoreFocus();

    //---------------------------------------------------------------------------------------------
    // Events
    //---------------------------------------------------------------------------------------------

    Component.onCompleted: if (DialogErrorModel.count) errorPopup.state = "visible"

    Component.onDestruction: {
        if (questionDialog.dialogId !== null) {
            dialogModel.dismiss(questionDialog.dialogId)
            questionDialog.dialogId = null
        } if (loginDialog.dialogId !== null) {
            dialogModel.dismiss(loginDialog.dialogId)
            loginDialog.dialogId = null
        }
    }

    //---------------------------------------------------------------------------------------------
    // Functions
    //---------------------------------------------------------------------------------------------

    function ask(text, acceptCb, rejectCb, buttons) {
        customDialog.ask(text, acceptCb, rejectCb, buttons)
    }

    //---------------------------------------------------------------------------------------------
    // Connections
    //---------------------------------------------------------------------------------------------

    Connections
    {
        target: dialogModel

        onLogin: {
            loginDialog.dialogId = dialogId
            loginDialog.title = title
            loginDialog.defaultUsername = defaultUsername
            loginDialog.open()
        }

        onQuestion: {
            questionDialog.dialogId = dialogId
            questionDialog.title = title
            questionDialog.text = text
            questionDialog.cancelTxt = cancel
            questionDialog.action1Txt = action1
            questionDialog.action2Txt = action2
            questionDialog.open()
        }

        onProgress: {
            console.warn("onProgressUpdated is not implemented")
        }

        onProgressUpdated: {
            console.warn("onProgressUpdated is not implemented")
        }

        onCancelled: {
            if (questionDialog.dialogId === dialogId) {
                questionDialog.close()
                questionDialog.dialogId = null
                dialogModel.dismiss(dialogId)
            } else if (loginDialog.dialogId === dialogId)  {
                loginDialog.close()
                loginDialog.dialogId = null
                dialogModel.dismiss(dialogId)
            } else {
                dialogModel.dismiss(dialogId)
            }
        }
    }

    Connections
    {
        target: DialogErrorModel

        onCountChanged: errorPopup.state = "visible"
    }

    //---------------------------------------------------------------------------------------------
    // Childs
    //---------------------------------------------------------------------------------------------

    DialogModel {
        id: dialogModel
        ctx: MainCtx
    }


    Widgets.DrawerExt {
        id: errorPopup
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        edge: Widgets.DrawerExt.Edges.Bottom
        width: parent.width * 0.8
        z: 10

        component: Rectangle {
            color: "gray"
            opacity: 0.7
            width: errorPopup.width
            height: VLCStyle.fontHeight_normal * 5
            radius: VLCStyle.fontHeight_normal / 2

            Flickable {
                anchors.fill: parent
                anchors.margins: VLCStyle.fontHeight_normal / 2
                ScrollBar.vertical: ScrollBar{}
                contentY: VLCStyle.fontHeight_normal * ((DialogErrorModel.count * 2) - 4)
                clip: true

                ListView {
                    width: parent.width
                    height: VLCStyle.fontHeight_normal * DialogErrorModel.count * 2
                    model: DialogErrorModel
                    delegate: Column {
                        Text {
                            text: model.title
                            font.pixelSize: VLCStyle.fontSize_normal
                            font.bold: true
                            color: "red"
                        }
                        Text {
                            text: model.text
                            font.pixelSize: VLCStyle.fontSize_normal
                        }
                    }
                }
            }
        }

        state: "hidden"
        onStateChanged: {
            hideErrorPopupTimer.restart()
        }

        Timer {
            id: hideErrorPopupTimer
            interval: 5000
            repeat: false
            onTriggered: {
                errorPopup.state = "hidden"
            }
        }
    }

    ModalDialog {
        id: loginDialog

        //use var here as DialogId is a QGadget and passed by value
        property var dialogId: null
        property string defaultUsername: ""

        onAboutToHide: restoreFocus()
        rootWindow: root.bgContent

        contentItem: GridLayout {
            columns: 2

            Text {
                text: I18n.qtr("User")
                color: VLCStyle.colors.text
                font.pixelSize: VLCStyle.fontSize_normal
            }

            TextField {
                id: username

                focus: true
                text: loginDialog.defaultUsername
                font.pixelSize: VLCStyle.fontSize_normal

                Layout.fillWidth:true

                Navigation.downItem: password
                Keys.priority: Keys.AfterItem
                Keys.onPressed: Navigation.defaultKeyAction(event)
            }

            Text {
                text: I18n.qtr("Password")
                color: VLCStyle.colors.text
                font.pixelSize: VLCStyle.fontSize_normal
            }

            TextField {
                id: password

                echoMode: TextInput.Password
                font.pixelSize: VLCStyle.fontSize_normal
                Layout.fillWidth:true

                Navigation.upItem: username
                Navigation.downItem: savePassword
                Keys.priority: Keys.AfterItem
                Keys.onPressed: Navigation.defaultKeyAction(event)
            }

            Text {
                text: I18n.qtr("Save password")
                color: VLCStyle.colors.text
                font.pixelSize: VLCStyle.fontSize_normal
            }
            CheckBox {
                id: savePassword

                Navigation.upItem: password
                Navigation.downItem: loginButtons
                Keys.priority: Keys.AfterItem
                Keys.onPressed: Navigation.defaultKeyAction(event)
            }
        }

        footer: FocusScope {
            id: loginButtons
            implicitHeight: VLCStyle.icon_normal

            Rectangle {
                color: VLCStyle.colors.topBanner
                anchors.fill: parent

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: VLCStyle.margin_xxsmall
                    anchors.rightMargin: VLCStyle.margin_xxsmall

                    Widgets.TextToolButton {
                        id: loginCancel
                        Layout.fillWidth: true
                        text: I18n.qtr("cancel")

                        Navigation.upItem: savePassword
                        Navigation.rightItem: loginOk
                        Keys.priority: Keys.AfterItem
                        Keys.onPressed: Navigation.defaultKeyAction(event)

                        onClicked: {
                            loginDialog.reject()
                            loginDialog.close()
                        }
                    }

                    Widgets.TextToolButton {
                        id: loginOk
                        Layout.fillWidth: true
                        text: I18n.qtr("Ok")
                        focus: true

                        Navigation.upItem: savePassword
                        Navigation.leftItem: loginCancel
                        Keys.priority: Keys.AfterItem
                        Keys.onPressed: Navigation.defaultKeyAction(event)

                        onClicked: {
                            loginDialog.accept()
                            loginDialog.close()
                        }
                    }
                }
            }
        }

        onAccepted: {
            if (loginDialog.dialogId !== null) {
                dialogModel.post_login(loginDialog.dialogId, username.text, password.text, savePassword.checked)
                loginDialog.dialogId = null
            }
        }
        onRejected: {
            if (loginDialog.dialogId !== null) {
                dialogModel.dismiss(loginDialog.dialogId)
                loginDialog.dialogId = null
            }
        }
    }

    ModalDialog {
        id: questionDialog

        //use var here as DialogId is a QGadget and passed by value
        property var dialogId: null
        property alias text: content.text
        property alias cancelTxt: cancel.text
        property alias action1Txt: action1.text
        property alias action2Txt: action2.text

        rootWindow: root.bgContent

        onAboutToHide: restoreFocus()

        contentItem: Text {
            id: content
            focus: false
            font.pixelSize: VLCStyle.fontSize_normal
            color: VLCStyle.colors.text
            wrapMode: Text.WordWrap
        }

        footer: FocusScope {
            focus: true
            id: questionButtons
            implicitHeight: VLCStyle.icon_normal

            Rectangle {
                color: VLCStyle.colors.topBanner
                anchors.fill: parent
                anchors.leftMargin: VLCStyle.margin_xxsmall
                anchors.rightMargin: VLCStyle.margin_xxsmall

                RowLayout {
                    anchors.fill: parent

                    Widgets.TextToolButton {
                        id: cancel

                        focus: true
                        visible: cancel.text !== ""

                        Layout.fillWidth: true

                        Navigation.rightItem: action1
                        Keys.priority: Keys.AfterItem
                        Keys.onPressed: Navigation.defaultKeyAction(event)

                        onClicked: {
                            dialogModel.dismiss(questionDialog.dialogId)
                            questionDialog.dialogId = null
                            questionDialog.close()
                        }
                    }

                    Widgets.TextToolButton {
                        id: action1

                        visible: action1.text !== ""

                        Layout.fillWidth: true

                        Navigation.leftItem: cancel
                        Navigation.rightItem: action2
                        Keys.priority: Keys.AfterItem
                        Keys.onPressed: Navigation.defaultKeyAction(event)

                        onClicked: {
                            dialogModel.post_action1(questionDialog.dialogId)
                            questionDialog.dialogId = null
                            questionDialog.close()
                        }
                    }

                    Widgets.TextToolButton {
                        id: action2
                        visible: action2.text !== ""

                        Layout.fillWidth: true

                        Navigation.leftItem: action1
                        Keys.priority: Keys.AfterItem
                        Keys.onPressed: Navigation.defaultKeyAction(event)

                        onClicked: {
                            dialogModel.post_action2(questionDialog.dialogId)
                            questionDialog.dialogId = null
                            questionDialog.close()
                        }
                    }
                }
            }
        }
    }

    CustomDialog {
        id: customDialog
        rootWindow: root.bgContent
        onAboutToHide: restoreFocus()
    }

    Loader {
        id: toolbarEditorDialogLoader
        active: false
        source: "qrc:///dialogs/ToolbarEditorDialog.qml"

        Connections {
            target: toolbarEditorDialogLoader.item

            onUnload: {
                toolbarEditorDialogLoader.active = false
            }
        }

        Connections {
            target: DialogsProvider

            onShowToolbarEditorDialog: {
                toolbarEditorDialogLoader.active = true
                toolbarEditorDialogLoader.item.open()
            }
        }
    }
}
