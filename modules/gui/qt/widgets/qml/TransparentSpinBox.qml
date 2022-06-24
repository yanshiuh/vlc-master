
/*****************************************************************************
 * Copyright (C) 2020 VLC authors and VideoLAN
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
import QtQuick.Templates 2.4 as T

import org.videolan.vlc 0.1

import "qrc:///widgets/" as Widgets
import "qrc:///style/"

T.SpinBox {
    id: control

    property color color: "white"
    property int borderWidth: VLCStyle.dp(1, VLCStyle.scale)
    property color borderColor: control.activeFocus
                                || control.hovered ? VLCStyle.colors.accent : Qt.rgba(
                                                         1, 1, 1, .2)
    value: 50
    editable: true
    from: 0
    to: 99999
    padding: VLCStyle.dp(6, VLCStyle.scale)
    font.pixelSize: VLCStyle.fontSize_normal
    implicitHeight: VLCStyle.fontHeight_normal + control.topPadding + control.bottomPadding

    Keys.priority: Keys.AfterItem
    Keys.onPressed: Navigation.defaultKeyAction(event)

    contentItem: TextInput {
        // NOTE: This is required for InterfaceWindowHandler::applyKeyEvent.
        property bool visualFocus: control.activeFocus

        z: 2
        text: control.textFromValue(control.value, control.locale)
        color: control.color
        font: control.font
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
        readOnly: !control.editable
        validator: control.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        padding: 0
    }

    background: Rectangle {
        color: "transparent"
        border.width: control.borderWidth
        border.color: control.borderColor
    }

    up.indicator: T.Label {
        x: control.mirrored ? 0 : parent.width - width
        z: 4
        height: parent.height
        width: implicitWidth
        text: "\uff0b" // Full-width Plus
        font.pixelSize: control.font.pixelSize
        color: !control.up.pressed ? control.color : VLCStyle.colors.accent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.leftPadding
        rightPadding: control.rightPadding

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onPressed: {
                control.up.pressed = true
                control.increase()
                mouse.accepted = true
            }
            onReleased: {
                control.up.pressed = false
                mouse.accepted = true
            }
        }
    }

    down.indicator: T.Label {
        x: control.mirrored ? parent.width - width : 0
        z: 4
        height: parent.height
        width: implicitWidth
        text: "\uff0d" // Full-width Hyphen-minus
        font.pixelSize: control.font.pixelSize
        color: !control.down.pressed ? control.color : VLCStyle.colors.accent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.leftPadding
        rightPadding: control.rightPadding

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onPressed: {
                control.down.pressed = true
                control.decrease()
                mouse.accepted = true
            }
            onReleased: {
                control.down.pressed = false
                mouse.accepted = true
            }
        }
    }
}
