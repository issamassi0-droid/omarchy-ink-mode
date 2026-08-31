import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property real iconSize: Style.bar.iconCanvas
  property color color: Color.foreground
  property bool slashed: false
  property string fontFamily: Style.font.family

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  OpticalGlyph {
    anchors.fill: parent
    text: "󰏪"
    fontFamily: root.fontFamily
    fontSize: Style.bar.iconFont
    color: root.color
  }

  Rectangle {
    visible: root.slashed
    anchors.centerIn: parent
    width: parent.width * 1.22
    height: Math.max(2, parent.height * 0.14)
    radius: height / 2
    color: root.color
    rotation: -135
  }
}
