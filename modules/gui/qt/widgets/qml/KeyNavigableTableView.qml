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
import QtQml.Models 2.2
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.0
import org.videolan.vlc 0.1

import "qrc:///util/" as Util
import "qrc:///widgets/" as Widgets
import "qrc:///style/"

// FIXME: Maybe we could inherit from KeyNavigableListView directly.
FocusScope {
    id: root

    // Properties

    property var sortModel: []

    property Component colDelegate: Widgets.ScrollingText {
        id: textRect

        property var rowModel: parent.rowModel
        property var model: parent.colModel
        property color foregroundColor: parent.foregroundColor

        label: text
        forceScroll: parent.currentlyFocused
        width: parent.width
        clip: scrolling

        Widgets.ListLabel {
            id: text

            anchors.verticalCenter: parent.verticalCenter
            text: !rowModel ? "" : (rowModel[model.criteria] || "")
            color: textRect.foregroundColor
        }
    }

    property Component tableHeaderDelegate: Widgets.CaptionLabel {
        text: model.text || ""
    }

    readonly property real sectionWidth: !!section.property ? VLCStyle.table_section_width : 0

    readonly property real usedRowSpace: {
        var s = 0
        for (var i in sortModel)
            s += sortModel[i].width + root.horizontalSpacing
        return s + root._contextButtonHorizontalSpace + (VLCStyle.margin_xxxsmall * 2)
    }

    property Component header: Item{}
    property Item headerItem: view.headerItem.loadedHeader
    property color headerColor
    property int headerTopPadding: 0

    property Util.SelectableDelegateModel selectionDelegateModel
    property real rowHeight: VLCStyle.tableRow_height
    readonly property int _contextButtonHorizontalSpace: VLCStyle.icon_normal
    property int horizontalSpacing: VLCStyle.column_margin_width

    property real availableRowWidth: 0
    property real _availabeRowWidthLastUpdateTime: Date.now()
    readonly property real _currentAvailableRowWidth: root.width
                                                      - root.sectionWidth * 2
                                                      - (root.horizontalSpacing + _contextButtonHorizontalSpace)
                                                      - (VLCStyle.margin_xxxsmall * 2)

    property Item dragItem

    // Aliases

    property alias topMargin: view.topMargin
    property alias bottomMargin: view.bottomMargin
    property alias leftMargin: view.leftMargin
    property alias rightMargin: view.rightMargin

    property alias spacing: view.spacing

    property alias model: view.model

    property alias delegate: view.delegate

    property alias contentY     : view.contentY
    property alias contentHeight: view.contentHeight

    property alias interactive: view.interactive

    property alias section: view.section

    property alias currentIndex: view.currentIndex
    property alias currentItem: view.currentItem

    property alias headerPositioning: view.headerPositioning

    property alias tableHeaderItem: view.headerItem

    property alias footerItem: view.footerItem
    property alias footer: view.footer

    property alias fadeColor: view.fadeColor
    property alias fadeSize: view.fadeSize

    property alias add:       view.add
    property alias displaced: view.displaced

    property alias listScrollBar: view.listScrollBar
    property alias listView: view

    property alias displayMarginEnd: view.displayMarginEnd

    // Signals

    //forwarded from subview
    signal actionForSelection( var selection )
    signal contextMenuButtonClicked(Item menuParent, var menuModel, point globalMousePos)
    signal rightClick(Item menuParent, var menuModel, point globalMousePos)
    signal itemDoubleClicked(var index, var model)

    // Settings

    Accessible.role: Accessible.Table

    // Events

    Component.onDestruction: {
        _qtAvoidSectionUpdate()
    }

    on_CurrentAvailableRowWidthChanged: availableRowWidthUpdater.enqueueUpdate()

    /*
     *define the initial position/selection
     * This is done on activeFocus rather than Component.onCompleted because delegateModel.
     * selectedGroup update itself after this event
     */
    onActiveFocusChanged: {
        if (activeFocus == false || view.count == 0)
            return;

        if (view.currentIndex == -1)
            view.currentIndex = 0;

        if (selectionDelegateModel.hasSelection === false)
            selectionDelegateModel.select(model.index(view.currentIndex, 0),
                                          ItemSelectionModel.ClearAndSelect);

        view.forceActiveFocus();
    }

    // Functions

    function setCurrentItemFocus(reason) {
        view.setCurrentItemFocus(reason);
    }

    function positionViewAtIndex(index, mode) {
        view.positionViewAtIndex(index, mode)
    }

    function positionViewAtBeginning() {
        view.positionViewAtBeginning()
    }

    function _qtAvoidSectionUpdate() {
        // Qt SEG. FAULT WORKAROUND

        // There exists a Qt bug that tries to access null
        // pointer while updating sections. Qt does not
        // check if `QQmlEngine::contextForObject(sectionItem)->parentContext()`
        // is null and when it's null which might be the case for
        // views during destruction it causes segmentation fault.

        // As a workaround, when section delegate is set to null
        // during destruction, Qt does not proceed with updating
        // the sections so null pointer access is avoided. Updating
        // sections during destruction should not make sense anyway.

        // Setting section delegate to null seems to has no
        // negative impact and safely could be used as a fix.
        // However, the problem lying beneath prevails and
        // should be taken care of sooner than later.

        // Affected Qt versions are 5.11.3, and 5.15.2 (not
        // limited).

        section.delegate = null
    }

    // Childs

    Timer {
        id: availableRowWidthUpdater

        interval: 100
        triggeredOnStart: false
        repeat: false
        onTriggered: {
            _update()
        }

        function _update() {
            root.availableRowWidth = root._currentAvailableRowWidth
            root._availabeRowWidthLastUpdateTime = Date.now()
        }

        function enqueueUpdate() {
            // updating availableRowWidth is expensive because of property bindings in sortModel
            // and availableRowWidth is dependent on root.width which can update in a burst
            // so try to maintain a minimum time gap between subsequent availableRowWidth updates
            var sinceLastUpdate = Date.now() - root._availabeRowWidthLastUpdateTime
            if ((root.availableRowWidth === 0) || (sinceLastUpdate > 128 && !availableRowWidthUpdater.running)) {
                _update()
            } else if (!availableRowWidthUpdater.running) {
                availableRowWidthUpdater.interval = Math.max(128 - sinceLastUpdate, 32)
                availableRowWidthUpdater.start()
            }
        }
    }

    KeyNavigableListView {
        id: view

        anchors.fill: parent

        focus: true

        headerPositioning: ListView.OverlayHeader

        fadeColor: VLCStyle.colors.bg

        onDeselectAll: {
            if (selectionDelegateModel) {
                selectionDelegateModel.clear()
            }
        }

        onShowContextMenu: {
            if (selectionDelegateModel.hasSelection)
                root.rightClick(null, null, globalPos);
        }

        header: Rectangle {

            readonly property alias contentX: row.x
            readonly property alias contentWidth: row.width
            property alias loadedHeader: headerLoader.item

            width: Math.max(view.width, root.usedRowSpace + root.sectionWidth)
            height: col.height
            color: headerColor
            visible: view.count > 0
            z: 3

            // with inline header positioning and for `root.header` which changes it's height after loading,
            // in such cases after `root.header` completes, the ListView will try to maintain the relative contentY,
            // and hide the completed `root.header`, try to show the `root.header` in such cases by manually
            // positiing view at beginning
            onHeightChanged: if (root.contentY < 0) root.positionViewAtBeginning()

            Widgets.ListLabel {
                x: contentX - VLCStyle.table_section_width
                y: row.y
                height: row.height
                topPadding: root.headerTopPadding
                leftPadding: VLCStyle.table_section_text_margin
                text: view.currentSection
                color: VLCStyle.colors.accent
                verticalAlignment: Text.AlignTop
                visible: view.headerPositioning === ListView.OverlayHeader
                         && text !== ""
                         && view.contentY > (row.height - col.height - row.topPadding)
            }

            Column {
                id: col

                width: parent.width
                height: implicitHeight

                Loader {
                    id: headerLoader

                    sourceComponent: root.header
                }

                Row {
                    id: row

                    x: Math.max(0, view.width - root.usedRowSpace) / 2 + root.sectionWidth
                    leftPadding: VLCStyle.margin_xxxsmall
                    rightPadding: VLCStyle.margin_xxxsmall
                    topPadding: root.headerTopPadding
                    bottomPadding: VLCStyle.margin_xsmall

                    spacing: root.horizontalSpacing

                    Repeater {
                        model: sortModel
                        MouseArea {
                            height: childrenRect.height
                            width: modelData.width || 1
                            //Layout.alignment: Qt.AlignVCenter

                            Loader {
                                property var model: modelData

                                sourceComponent: model.headerDelegate || root.tableHeaderDelegate
                            }

                            Text {
                                text: (root.model.sortOrder === Qt.AscendingOrder) ? "▼" : "▲"
                                visible: root.model.sortCriteria === modelData.criteria
                                font.pixelSize: VLCStyle.fontSize_normal
                                color: VLCStyle.colors.accent
                                anchors {
                                    right: parent.right
                                    leftMargin: VLCStyle.margin_xsmall
                                    rightMargin: VLCStyle.margin_xsmall
                                }
                            }
                            onClicked: {
                                if (root.model.sortCriteria !== modelData.criteria)
                                    root.model.sortCriteria = modelData.criteria
                                else
                                    root.model.sortOrder = (root.model.sortOrder === Qt.AscendingOrder) ? Qt.DescendingOrder : Qt.AscendingOrder
                            }
                        }
                    }

                    Item {
                        // placeholder for context button

                        width: root._contextButtonHorizontalSpace

                        height: 1
                    }
                }
            }
        }

        section.delegate: Widgets.ListLabel {
            x: view.headerItem.contentX - VLCStyle.table_section_width
            topPadding: VLCStyle.margin_xsmall
            bottomPadding: VLCStyle.margin_xxsmall
            leftPadding: VLCStyle.table_section_text_margin
            text: section
            color: VLCStyle.colors.accent
        }

        delegate: TableViewDelegate {}

        flickableDirection: Flickable.AutoFlickDirection
        contentWidth: root.usedRowSpace + root.sectionWidth

        onSelectAll: selectionDelegateModel.selectAll()
        onSelectionUpdated: selectionDelegateModel.updateSelection( keyModifiers, oldIndex, newIndex )
        onActionAtIndex: root.actionForSelection( selectionDelegateModel.selectedIndexes )

        Navigation.parentItem: root
    }
}
