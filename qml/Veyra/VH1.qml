import QtQuick

Text {
    color: Theme.t1
    font.family: Theme.fontUi
    font.pixelSize: Theme.fsH1
    font.weight: Font.DemiBold; font.variableAxes: Theme.axesDemiBold
    // M$M! arena: headings in spaced capitals.
    font.capitalization: Theme.capsMode
    font.letterSpacing: Theme.spacing(1.5)
}
