.pragma library
// Logical pixels shared by the QML cards and the one native videoHost.
// mirrored (M$M! frost): the settings and the start button on the left, the queue on the right.
function calculate(width, height, tab, mirrored) {
    const compact = width < 1120 || height < 500
    const margin = 12, top = 56, gap = 10
    const bodyHeight = Math.max(1, height - top - margin)
    const leftWidth = 260, rightWidth = 340
    const footerHeight = compact ? 60 : 116
    const body = { x: margin, y: top, width: Math.max(1, width - 2 * margin),
                   height: Math.max(1, bodyHeight - footerHeight - gap) }
    const flip = !!mirrored && !compact
    const left = compact ? body : { x: flip ? width - margin - leftWidth : margin, y: top, width: leftWidth, height: bodyHeight }
    const settings = compact ? body : { x: flip ? margin : width - margin - rightWidth, y: top,
        width: rightWidth, height: bodyHeight - footerHeight - gap }
    const footer = { x: compact ? margin : settings.x, y: height - margin - footerHeight,
        width: compact ? body.width : rightWidth, height: footerHeight }
    const centerX = compact ? margin : margin + (flip ? rightWidth : leftWidth) + gap
    const centerWidth = compact ? body.width : Math.max(1, width - margin * 2 - leftWidth - rightWidth - gap * 2)
    const centerHeight = compact ? body.height : bodyHeight
    const trimHeight = compact ? 72 : 110
    const preview = { x: centerX, y: top, width: centerWidth, height: Math.max(1, centerHeight - trimHeight - gap) }
    const trim = { x: centerX, y: top + centerHeight - trimHeight, width: centerWidth, height: trimHeight }
    return { compact: compact, left: left, settings: settings, footer: footer, preview: preview, trim: trim,
        video: !compact || tab === 1 ? preview : { x: 0, y: 0, width: 0, height: 0 } }
}
