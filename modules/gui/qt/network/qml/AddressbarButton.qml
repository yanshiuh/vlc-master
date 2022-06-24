
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
import QtQuick.Templates 2.4 as T

import "qrc:///style/"
import "qrc:///widgets/" as Widgets

T.AbstractButton {
    id: button

    // Properties

    property bool onlyIcon: true

    property bool highlighted: false

    // Aliases

    property alias foregroundColor: background.foregroundColor
    property alias backgroundColor: background.backgroundColor

    // Settings

    implicitWidth: Math.max(background.implicitWidth,
            (contentItem ? contentItem.implicitWidth : 0) + leftPadding + rightPadding)
    implicitHeight: Math.max(background.implicitHeight,
            (contentItem ? contentItem.implicitHeight : 0) + topPadding + bottomPadding)
    baselineOffset: contentItem ? contentItem.y + contentItem.baselineOffset : 0


    padding: VLCStyle.margin_xxsmall

    font.pixelSize: (onlyIcon) ? VLCIcons.pixelSize(VLCStyle.icon_normal)
                               : VLCStyle.fontSize_large

    // Children

    background: Widgets.AnimatedBackground {
        id: background

        active: visualFocus

        backgroundColor: "transparent"

        foregroundColor: (hovered) ? VLCStyle.colors.buttonTextHover
                                   : VLCStyle.colors.buttonBanner
    }

    contentItem: contentLoader.item

    Loader {
        id: contentLoader

        sourceComponent: (onlyIcon) ? iconTextContent
                                    : textContent
    }

    Component {
        id: iconTextContent

        Widgets.IconLabel {
            verticalAlignment: Text.AlignVCenter

            text: button.text

            elide: Text.ElideRight

            color: button.foregroundColor

            font.pixelSize: button.font.pixelSize
        }
    }

    Component {
        id: textContent

        T.Label {
            verticalAlignment: Text.AlignVCenter

            text: button.text

            elide: Text.ElideRight

            color: button.foregroundColor

            font.pixelSize: button.font.pixelSize

            font.weight: (highlighted) ? Font.DemiBold : Font.Normal
        }
    }
}
