import Quickshell.Services.Pipewire
import QtQuick

// Audio outputs; clicking one makes it the default sink, which the volume keys
// and the slider control.
Column {
    id: root

    spacing: 2

    Repeater {
        model: Audio.sinks

        delegate: ListRow {
            required property PwNode modelData
            readonly property bool current: modelData.id === Audio.sink?.id

            icon: Audio.isBluetooth(modelData) ? Icons.headphones : Icons.volume[2]
            text: Audio.label(modelData)
            highlighted: current
            detail: current ? "Default" : ""
            onClicked: Audio.setSink(modelData)
        }
    }
}
