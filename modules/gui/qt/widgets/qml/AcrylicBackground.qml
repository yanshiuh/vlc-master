/*****************************************************************************
 * Copyright (C) 2021 VLC authors and VideoLAN
 *
 * Authors: Prince Gupta <guptaprince8832@gmail.com>
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

import org.videolan.vlc 0.1

import "qrc:///style/"

// This Component uses layering, avoid adding children to this widget
Item {
    id: root

    readonly property bool usingAcrylic: visible && enabled && AcrylicController.enabled

    property color tintColor: VLCStyle.colors.setColorAlpha(VLCStyle.colors.bg, 0.7)

    property color alternativeColor: VLCStyle.colors.bgAlt

    property real _blend: usingAcrylic ? AcrylicController.uiTransluency : 0

    layer.enabled: true
    layer.effect: ShaderEffect {
        property color overlay: VLCStyle.colors.blendColors(root.tintColor, root.alternativeColor, root._blend)

        blending: false
        fragmentShader: "
            uniform lowp vec4 overlay;
            void main() { gl_FragColor = overlay; }
        "
    }
}
