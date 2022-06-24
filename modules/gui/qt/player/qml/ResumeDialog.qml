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
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4
import QtQuick.Templates 2.4 as T

import org.videolan.vlc 0.1

import "qrc:///style/"
import "qrc:///widgets/" as Widgets

FocusScope {
    id: resumePanel

    property VLCColors colors: VLCStyle.colors

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    visible: false

    signal hidden()

    function showResumePanel ()
    {
        resumePanel.visible = true
        continueBtn.forceActiveFocus()
        resumeTimeout.start()
    }

    function hideResumePanel() {
        resumeTimeout.stop()
        resumePanel.visible = false
        Player.acknowledgeRestoreCallback()
        hidden()
    }

    Timer {
        id: resumeTimeout
        interval: 10000
        onTriggered: {
            resumePanel.visible = false
            hidden()
        }
    }

    Connections {
        target: Player
        onCanRestorePlaybackChanged: {
            if (Player.canRestorePlayback) {
                showResumePanel()
            } else {
                hideResumePanel()
            }
        }
    }

    Component.onCompleted: {
        if (Player.canRestorePlayback) {
            showResumePanel()
        }
    }

    Navigation.cancelAction: function() {
        hideResumePanel()
    }

    //drag and dbl click the titlebar in CSD mode
    Loader {
        anchors.fill: parent
        active: MainCtx.clientSideDecoration
        source: "qrc:///widgets/CSDTitlebarTapNDrapHandler.qml"
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.leftMargin: VLCStyle.margin_small
        spacing: VLCStyle.margin_small

        //FIXME use the right xxxLabel class
        T.Label {
            Layout.preferredHeight: implicitHeight
            Layout.preferredWidth: implicitWidth

            color: resumePanel.colors.playerFg
            font.pixelSize: VLCStyle.fontSize_normal
            font.bold: true

            text: I18n.qtr("Do you want to restart the playback where you left off?")
        }

        Widgets.TabButtonExt {
            id: continueBtn
            Layout.preferredHeight: implicitHeight
            Layout.preferredWidth: implicitWidth
            text: I18n.qtr("Continue")
            font.bold: true
            color: resumePanel.colors.playerFg
            focus: true
            onClicked: {
                Player.restorePlaybackPos()
                hideResumePanel()
            }

            Navigation.parentItem: resumePanel
            Navigation.rightItem: closeBtn
            Keys.priority: Keys.AfterItem
            Keys.onPressed:  continueBtn.Navigation.defaultKeyAction(event)
        }

        Widgets.TabButtonExt {
            id: closeBtn
            Layout.preferredHeight: implicitHeight
            Layout.preferredWidth: implicitWidth
            text: I18n.qtr("Dismiss")
            font.bold: true
            color: resumePanel.colors.playerFg
            onClicked: hideResumePanel()

            Navigation.parentItem: resumePanel
            Navigation.leftItem: continueBtn
            Keys.priority: Keys.AfterItem
            Keys.onPressed: closeBtn.Navigation.defaultKeyAction(event)
        }

        Item {
            Layout.fillWidth: true
        }

        Loader {
            id: csdDecorations

            Layout.alignment: Qt.AlignTop | Qt.AlignRight

            focus: false
            height: VLCStyle.icon_normal
            active: MainCtx.clientSideDecoration
            enabled: MainCtx.clientSideDecoration
            visible: MainCtx.clientSideDecoration
            source: "qrc:///widgets/CSDWindowButtonSet.qml"
            onLoaded: {
                item.color = Qt.binding(function() { return resumePanel.colors.playerFg })
                item.hoverColor = Qt.binding(function() { return resumePanel.colors.windowCSDButtonDarkBg })
            }
        }
    }
}

