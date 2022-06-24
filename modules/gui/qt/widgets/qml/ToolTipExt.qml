/*****************************************************************************
 * Copyright (C) 2021 VLC authors and VideoLAN
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

import "qrc:///style/"

ToolTip {
    id: control

    margins: VLCStyle.margin_xsmall
    padding: VLCStyle.margin_xsmall

    font.pixelSize: VLCStyle.fontSize_normal

    property VLCColors colors: VLCStyle.colors

    contentItem: Text {
        text: control.text
        font: control.font

        color: colors.tooltipTextColor
    }

    background: Rectangle {
        border.color: colors.border
        color: colors.tooltipColor
    }
}
