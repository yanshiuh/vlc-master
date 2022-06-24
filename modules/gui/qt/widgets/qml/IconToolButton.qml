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
import QtQuick.Templates 2.4 as T

import org.videolan.vlc 0.1

import "qrc:///widgets/" as Widgets
import "qrc:///style/"

T.ToolButton {
    id: control

    // Properties

    property bool paintOnly: false

    property int size: VLCStyle.icon_normal

    property string iconText: ""

    // Style

    // background colors
    // NOTE: We want the background to be transparent for IconToolButton(s).
    property color backgroundColor: "transparent"
    property color backgroundColorHover: "transparent"

    // foreground colors based on state
    property color color: VLCStyle.colors.icon
    property color colorHover: VLCStyle.colors.buttonTextHover
    property color colorHighlighted: VLCStyle.colors.accent
    property color colorDisabled: paintOnly ? color : VLCStyle.colors.textInactive

    // Aliases


    // active border color
    property alias colorFocus: background.activeBorderColor

    // Settings

    padding: 0

    enabled: !paintOnly

    implicitWidth: Math.max(background.implicitWidth,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background.implicitHeight,
                            contentItem.implicitHeight + topPadding + bottomPadding)
    baselineOffset: contentItem.y + contentItem.baselineOffset

    // Keys

    Keys.priority: Keys.AfterItem

    Keys.onPressed: Navigation.defaultKeyAction(event)

    // Childs

    T.ToolTip.text: control.text
    T.ToolTip.delay: VLCStyle.delayToolTipAppear

    background: AnimatedBackground {
        id: background

        implicitWidth: size
        implicitHeight: size

        active: control.visualFocus

        backgroundColor: {
            if (control.hovered)
                return control.backgroundColorHover;
            // if base color is transparent, animation starts with black color
            else if (control.backgroundColor.a === 0)
                return VLCStyle.colors.setColorAlpha(control.backgroundColorHover, 0);
            else
                return control.backgroundColor;
        }

        foregroundColor: {
            if (control.highlighted)
                return control.colorHighlighted;
            else if (control.hovered)
                return control.colorHover;
            else if (!control.enabled)
                return control.colorDisabled;
            else
                return control.color;
        }

        activeBorderColor: VLCStyle.colors.bgFocus
    }

    contentItem: T.Label {
        anchors.centerIn: parent

        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        text: iconText

        color: background.foregroundColor

        font.pixelSize: VLCIcons.pixelSize(size)
        font.family: VLCIcons.fontFamily
        font.underline: control.font.underline

        Accessible.ignored: true

        T.Label {
            anchors.centerIn: parent

            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter

            visible: !paintOnly && control.checked

            text: VLCIcons.active_indicator

            color: background.foregroundColor

            font.pixelSize: VLCIcons.pixelSize(size)
            font.family: VLCIcons.fontFamily

            Accessible.ignored: true
        }
    }
}
