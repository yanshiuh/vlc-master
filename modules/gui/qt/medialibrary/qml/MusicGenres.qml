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
import QtQuick.Templates 2.4 as T
import QtQml.Models 2.2
import org.videolan.vlc 0.1
import org.videolan.medialib 0.1

import "qrc:///util/" as Util
import "qrc:///widgets/" as Widgets
import "qrc:///main/" as MainInterface
import "qrc:///style/"

FocusScope {
    id: root
    property alias model: genreModel
    property var sortModel: [
        { text: I18n.qtr("Alphabetic"), criteria: "title" }
    ]

    readonly property var currentIndex: _currentView.currentIndex
    //the index to "go to" when the view is loaded
    property int initialIndex: 0

    property alias _currentView: view.currentItem

    signal showAlbumView(var id, string name, int reason)

    onInitialIndexChanged:  resetFocus()

    Component.onCompleted: loadView()

    function loadView() {
        if (MainCtx.gridView) {
            view.replace(gridComponent)
        } else {
            view.replace(tableComponent)
        }
    }

    function resetFocus() {
        if (genreModel.count === 0) {
            return
        }
        var initialIndex = root.initialIndex
        if (initialIndex >= genreModel.count)
            initialIndex = 0
        selectionModel.select(genreModel.index(initialIndex, 0), ItemSelectionModel.ClearAndSelect)
        if (_currentView)
            _currentView.positionViewAtIndex(initialIndex, ItemView.Contain)
    }

    function setCurrentItemFocus(reason) {
        _currentView.setCurrentItemFocus(reason);
    }

    MLGenreModel {
        id: genreModel
        ml: MediaLib

        coverDefault: VLCStyle.noArtAlbumCover

        onCountChanged: {
            if (genreModel.count > 0 && !selectionModel.hasSelection) {
                root.resetFocus()
            }
        }
    }

    function _actionAtIndex(index) {
        if (selectionModel.selectedIndexes.length > 1) {
            MediaLib.addAndPlay(model.getIdsForIndexes(selectionModel.selectedIndexes))
        } else if (selectionModel.selectedIndexes.length === 1) {
            var sel = selectionModel.selectedIndexes[0]
            var model = genreModel.getDataAt(sel)
            showAlbumView(model.id, model.name, Qt.TabFocusReason)
        }
    }

    Util.SelectableDelegateModel {
        id: selectionModel

        model: genreModel
    }

    Widgets.MLDragItem {
        id: genreDragItem

        mlModel: genreModel

        indexes: selectionModel.selectedIndexes

        titleRole: "name"
    }

    /*
     *define the initial position/selection
     * This is done on activeFocus rather than Component.onCompleted because selectionModel.
     * selectedGroup update itself after this event
     */
    onActiveFocusChanged: {
        if (activeFocus && genreModel.count > 0 && !selectionModel.hasSelection) {
            var initialIndex = 0
            if (_currentView.currentIndex !== -1)
                initialIndex = _currentView.currentIndex
            selectionModel.select(genreModel.index(initialIndex, 0), ItemSelectionModel.ClearAndSelect)
            _currentView.currentIndex = initialIndex
        }
    }

    Util.MLContextMenu {
        id: contextMenu

        model: genreModel
    }

    /* Grid View */
    Component {
        id: gridComponent
        MainInterface.MainGridView {
            id: gridView_id

            selectionDelegateModel: selectionModel
            model: genreModel
            topMargin: VLCStyle.margin_large

            Widgets.GridShadows {
                id: shadows

                leftPadding: 0
                coverWidth: VLCStyle.colWidth(2)
                coverHeight: shadows.coverWidth / 2
            }

           delegate: Widgets.GridItem {
                id: item

                property var model: ({})
                property int index: -1

                width: VLCStyle.colWidth(2)
                height: width / 2
                pictureWidth: width
                pictureHeight: height
                image: model.cover || VLCStyle.noArtAlbumCover
                playCoverBorderWidth: VLCStyle.dp(3, VLCStyle.scale)
                dragItem: genreDragItem
                unselectedUnderlay: shadows.unselected
                selectedUnderlay: shadows.selected

                onItemDoubleClicked: root.showAlbumView(model.id, model.name, Qt.MouseFocusReason)
                onItemClicked: gridView_id.leftClickOnItem(modifier, item.index)

                onPlayClicked: {
                    if (model.id)
                        MediaLib.addAndPlay(model.id)
                }

                onContextMenuButtonClicked: {
                    gridView_id.rightClickOnItem(index)
                    contextMenu.popup(selectionModel.selectedIndexes, globalMousePos)
                }

                pictureOverlay: Item {
                    Rectangle
                    {
                        anchors.fill: parent

                        radius: VLCStyle.gridCover_radius

                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.3) }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.7) }
                        }
                    }

                    Column {
                        anchors.centerIn: parent

                        //FIXME use the right xxxLabel class
                        T.Label {
                             width: item.width
                             elide: Text.ElideRight
                             font.pixelSize: VLCStyle.fontSize_large
                             font.weight: Font.DemiBold
                             text: model.name || I18n.qtr("Unknown genre")
                             color: "white"
                             horizontalAlignment: Text.AlignHCenter
                        }

                        Widgets.CaptionLabel {
                            width: item.width
                            text: model.nb_tracks > 1 ? I18n.qtr("%1 Tracks").arg(model.nb_tracks) : I18n.qtr("%1 Track").arg(model.nb_tracks)
                            opacity: .7
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            focus: true

            cellWidth: VLCStyle.colWidth(2)
            cellHeight: cellWidth / 2

            onActionAtIndex: _actionAtIndex(index)

            Navigation.parentItem: root
            Navigation.cancelAction: function() {
                if (_currentView.currentIndex <= 0)
                    root.Navigation.defaultNavigationCancel()
                else
                    _currentView.currentIndex = 0;
            }
        }
    }

    Component {
        id: tableComponent
        /* Table View */
        MainInterface.MainTableView {
            id: tableView_id

            readonly property int _nameColSpan: Math.max(
                                                    VLCStyle.gridColumnsForWidth(tableView_id.availableRowWidth - VLCStyle.listAlbumCover_width - VLCStyle.column_margin_width) - 1
                                                    , 1)

            model: genreModel
            selectionDelegateModel: selectionModel
            headerColor: VLCStyle.colors.bg
            focus: true
            onActionForSelection: _actionAtIndex(selection)
            Navigation.parentItem: root
            Navigation.cancelAction: function() {
                if (_currentView.currentIndex <= 0)
                    root.Navigation.defaultNavigationCancel()
                else
                    _currentView.currentIndex = 0;
            }
            dragItem: genreDragItem
            rowHeight: VLCStyle.tableCoverRow_height
            headerTopPadding: VLCStyle.margin_normal

            sortModel:  [
                { isPrimary: true, criteria: "cover", width: VLCStyle.listAlbumCover_width, headerDelegate: tableColumns.titleHeaderDelegate, colDelegate: tableColumns.titleDelegate },
                { criteria: "name", width: VLCStyle.colWidth(tableView_id._nameColSpan), text: I18n.qtr("Name") },
                { criteria: "nb_tracks", width: VLCStyle.colWidth(1), text: I18n.qtr("Tracks") }
            ]

            onItemDoubleClicked: {
                root.showAlbumView(model.id, model.name, Qt.MouseFocusReason)
            }

            onContextMenuButtonClicked: contextMenu.popup(selectionModel.selectedIndexes, globalMousePos)
            onRightClick: contextMenu.popup(selectionModel.selectedIndexes, globalMousePos)

            Widgets.TableColumns {
                id: tableColumns

                showTitleText: false
                titleCover_height: VLCStyle.listAlbumCover_height
                titleCover_width: VLCStyle.listAlbumCover_width
                titleCover_radius: VLCStyle.listAlbumCover_radius
            }
        }
    }

    Widgets.StackViewExt {
        id: view

        initialItem: MainCtx.gridView ? gridComponent : tableComponent

        anchors.fill: parent
        focus: genreModel.count !== 0
    }

    Connections {
        target: MainCtx
        onGridViewChanged: {
            if (MainCtx.gridView) {
                view.replace(gridComponent)
            } else {
                view.replace(tableComponent)
            }
        }
    }

    EmptyLabel {
        anchors.fill: parent
        visible: genreModel.count === 0
        focus: genreModel.count === 0
        text: I18n.qtr("No genres found\nPlease try adding sources, by going to the Network tab")
        Navigation.parentItem: root
        cover: VLCStyle.noArtAlbumCover
    }
}
