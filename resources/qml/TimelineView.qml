import QtQuick 2.6
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.2
import QtGraphicalEffects 1.0
import QtQuick.Window 2.2

import im.nheko 1.0

import "./delegates"

Item {
	property var colors: currentActivePalette
	property var systemInactive: SystemPalette { colorGroup: SystemPalette.Disabled }
	property var inactiveColors: currentInactivePalette ? currentInactivePalette : systemInactive
	property int avatarSize: 40

	Rectangle {
		anchors.fill: parent
		color: colors.window

		Text {
			visible: !timelineManager.timeline && !timelineManager.isInitialSync
			anchors.centerIn: parent
			text: qsTr("No room open")
			font.pointSize: 24
			color: colors.windowText
		}

		BusyIndicator {
			anchors.centerIn: parent
			running: timelineManager.isInitialSync
			height: 200
			width: 200
		}

		ListView {
			id: chat

			cacheBuffer: 2000

			visible: timelineManager.timeline != null
			anchors.fill: parent

			anchors.leftMargin: 4
			anchors.rightMargin: scrollbar.width

			model: timelineManager.timeline

			onModelChanged: {
				if (model) {
					currentIndex = model.currentIndex
					if (model.currentIndex == count - 1) {
						positionViewAtEnd()
					} else {
						positionViewAtIndex(model.currentIndex, ListView.End)
					}
				}
			}

			ScrollBar.vertical: ScrollBar {
				id: scrollbar
				anchors.top: parent.top
				anchors.left: parent.right
				anchors.bottom: parent.bottom
				onPressedChanged: if (!pressed) chat.updatePosition()
			}

			property bool atBottom: false
			onCountChanged: {
				if (atBottom) {
					var newIndex = count - 1 // last index
					positionViewAtEnd()
					currentIndex = newIndex
					model.currentIndex = newIndex
				}

				if (contentHeight < height && model) {
					model.fetchHistory();
				}
			}

			onAtYBeginningChanged: if (atYBeginning) { chat.model.currentIndex = 0; chat.currentIndex = 0; model.fetchHistory(); }

			function updatePosition() {
				for (var y = chat.contentY + chat.height; y > chat.height; y -= 9) {
					var i = chat.itemAt(100, y);
					if (!i) continue;
					if (!i.isFullyVisible()) continue;
					chat.model.currentIndex = i.getIndex();
					chat.currentIndex = i.getIndex()
					atBottom = i.getIndex() == count - 1;
					break;
				}
			}
			onMovementEnded: updatePosition()

			spacing: 4
			delegate: TimelineRow {
				function isFullyVisible() {
					return height > 1 && (y - chat.contentY - 1) + height < chat.height
				}
				function getIndex() {
					return index;
				}
			}

			section {
				property: "section"
				delegate: Column {
					topPadding: 4
					bottomPadding: 4
					spacing: 8

					width: parent.width
					height: (section.includes(" ") ? dateBubble.height + 8 + userName.height : userName.height) + 8

					Label {
						id: dateBubble
						anchors.horizontalCenter: parent.horizontalCenter
						visible: section.includes(" ")
						text: chat.model.formatDateSeparator(new Date(Number(section.split(" ")[1])))
						color: colors.windowText

						height: contentHeight * 1.2
						width: contentWidth * 1.2
						horizontalAlignment: Text.AlignHCenter
						background: Rectangle {
							radius: parent.height / 2
							color: colors.dark
						}
					}
					Row {
						height: userName.height
						spacing: 4
						Avatar {
							width: avatarSize
							height: avatarSize
							url: chat.model.avatarUrl(section.split(" ")[0]).replace("mxc://", "image://MxcImage/")
							displayName: chat.model.displayName(section.split(" ")[0])

							MouseArea {
								anchors.fill: parent
								onClicked: chat.model.openUserProfile(section.split(" ")[0])
								cursorShape: Qt.PointingHandCursor
							}
						}

						Text { 
							id: userName
							text: chat.model.escapeEmoji(chat.model.displayName(section.split(" ")[0]))
							color: chat.model.userColor(section.split(" ")[0], colors.window)
							textFormat: Text.RichText

							MouseArea {
								anchors.fill: parent
								onClicked: chat.model.openUserProfile(section.split(" ")[0])
								cursorShape: Qt.PointingHandCursor
							}
						}
					}
				}
			}
		}
	}
}