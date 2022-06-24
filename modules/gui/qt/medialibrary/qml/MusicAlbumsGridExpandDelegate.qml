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
import QtQml.Models 2.11

import org.videolan.medialib 0.1
import org.videolan.controls 0.1
import org.videolan.vlc 0.1

import "qrc:///widgets/" as Widgets
import "qrc:///util/Helpers.js" as Helpers
import "qrc:///style/"

FocusScope {
    id: root

    property var model

    signal retract()

    implicitWidth: layout.implicitWidth

    implicitHeight: {
        var verticalMargins = layout.anchors.topMargin + layout.anchors.bottomMargin
        if (tracks.contentHeight < artAndControl.height)
            return artAndControl.height + verticalMargins
        return Math.min(tracks.contentHeight
                        , tracks.listView.headerItem.height + tracks.rowHeight * 6) // show a maximum of 6 rows
                + verticalMargins
    }

    // components should shrink with change of height, but it doesn't happen fast enough
    // causing expand and shrink animation bit laggy, so clip the delegate to fix it
    clip: true

    function setCurrentItemFocus(reason) {
        playActionBtn.forceActiveFocus(reason);
    }

    function _getStringTrack() {
        var count = Helpers.get(model, "nb_tracks", 0);

        if (count < 2)
            return I18n.qtr("%1 track").arg(count);
        else
            return I18n.qtr("%1 tracks").arg(count);
    }

    Rectangle {
        anchors.fill: parent
        color: VLCStyle.colors.expandDelegate

        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            color: VLCStyle.colors.border
            height: VLCStyle.expandDelegate_border
        }

        Rectangle {
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            color: VLCStyle.colors.border
            height: VLCStyle.expandDelegate_border
        }
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.leftMargin: VLCStyle.margin_normal
        anchors.topMargin: VLCStyle.margin_large
        anchors.rightMargin: VLCStyle.margin_small
        anchors.bottomMargin: VLCStyle.margin_xxsmall
        spacing: VLCStyle.margin_large

        FocusScope {
            id: artAndControl

            Layout.preferredHeight: artAndControlLayout.implicitHeight
            Layout.preferredWidth: artAndControlLayout.implicitWidth
            Layout.alignment: Qt.AlignTop

            focus: true

            Column {
                id: artAndControlLayout

                spacing: VLCStyle.margin_normal
                bottomPadding: VLCStyle.margin_large

                /* A bigger cover for the album */
                Item {
                    height: VLCStyle.expandCover_music_height
                    width: VLCStyle.expandCover_music_width

                    RoundImage {
                        id: expand_cover_id

                        height: VLCStyle.expandCover_music_height
                        width: VLCStyle.expandCover_music_width
                        radius: VLCStyle.expandCover_music_radius
                        source: Helpers.get(model, "cover", VLCStyle.noArtAlbumCover)
                    }

                    Widgets.ListCoverShadow {
                        source: expand_cover_id
                        anchors.fill: parent
                    }
                }

                Widgets.NavigableRow {
                    id: actionButtons

                    focus: true
                    width: expand_cover_id.width
                    spacing: VLCStyle.margin_small

                    Layout.alignment: Qt.AlignCenter

                    model: ObjectModel {
                        Widgets.ActionButtonPrimary {
                            id: playActionBtn

                            iconTxt: VLCIcons.play_outline
                            text: I18n.qtr("Play")
                            onClicked: MediaLib.addAndPlay( model.id )
                        }

                        Widgets.TabButtonExt {
                            id: enqueueActionBtn

                            iconTxt: VLCIcons.enqueue
                            text: I18n.qtr("Enqueue")
                            onClicked: MediaLib.addToPlaylist( model.id )
                        }
                    }

                    Navigation.parentItem: root
                    Navigation.rightItem: tracks
                }

            }
        }

        /* The list of the tracks available */
        MusicTrackListDisplay {
            id: tracks

            readonly property int _nbCols: VLCStyle.gridColumnsForWidth(tracks.availableRowWidth)

            property Component titleDelegate: RowLayout {
                property var rowModel: parent.rowModel

                anchors.fill: parent

                Widgets.ListLabel {
                    text: !!rowModel && !!rowModel.track_number ? rowModel.track_number : ""
                    color: foregroundColor
                    font.weight: Font.Normal

                    Layout.fillHeight: true
                    Layout.leftMargin: VLCStyle.margin_xxsmall
                    Layout.preferredWidth: VLCStyle.margin_large
                }

                Widgets.ListLabel {
                    text: !!rowModel && !!rowModel.title ? rowModel.title : ""
                    color: foregroundColor

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }
            }

            property Component titleHeaderDelegate: Row {

                Widgets.CaptionLabel {
                    text: "#"
                    width: VLCStyle.margin_large
                }

                Widgets.CaptionLabel {
                    text: I18n.qtr("Title")
                }
            }

            header: Column {
                width: tracks.width
                height: implicitHeight
                bottomPadding: VLCStyle.margin_large

                RowLayout {
                    width: parent.width

                    /* The title of the albums */
                    Widgets.SubtitleLabel {
                        id: expand_infos_title_id

                        text: Helpers.get(model, "title", I18n.qtr("Unknown title"))

                        Layout.fillWidth: true
                    }

                    Widgets.IconLabel {
                        text: VLCIcons.close

                        Layout.rightMargin: VLCStyle.margin_small

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.retract()
                        }
                    }
                }

                Widgets.CaptionLabel {
                    id: expand_infos_subtitle_id

                    width: parent.width
                    text: I18n.qtr("%1 - %2 - %3 - %4")
                        .arg(Helpers.get(model, "main_artist", I18n.qtr("Unknown artist")))
                        .arg(Helpers.get(model, "release_year", ""))
                        .arg(_getStringTrack())
                        .arg(Helpers.msToString(Helpers.get(model, "duration", 0)))
                }
            }

            clip: true // content may overflow if not enough space is provided
            headerPositioning: ListView.InlineHeader
            section.property: ""

            Layout.fillWidth: true
            Layout.fillHeight: true

            rowHeight: VLCStyle.tableRow_height
            headerColor: VLCStyle.colors.expandDelegate

            parentId: Helpers.get(root.model, "id")
            onParentIdChanged: {
                currentIndex = 0
            }

            sortModel: [
                { isPrimary: true, criteria: "title", width: VLCStyle.colWidth(Math.max(tracks._nbCols - 1, 1)), visible: true, text: I18n.qtr("Title"), showSection: "", colDelegate: titleDelegate, headerDelegate: titleHeaderDelegate },
                { criteria: "duration",               width: VLCStyle.colWidth(1), visible: true, showSection: "", colDelegate: tableColumns.timeColDelegate, headerDelegate: tableColumns.timeHeaderDelegate },
            ]

            Navigation.parentItem: root
            Navigation.leftItem: actionButtons

            Widgets.TableColumns {
                id: tableColumns
            }
        }
    }


    Keys.priority:  Keys.AfterItem
    Keys.onPressed:  root.Navigation.defaultKeyAction(event)
}
