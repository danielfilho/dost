import AppKit

/// A single indicator dot, sized by the dot-size setting. The whole view
/// drags the window.
final class IndicatorView: NSView {
    var style: IndicatorStyle {
        didSet { needsDisplay = true }
    }

    init(title: String?, style: IndicatorStyle) {
        self.style = style
        super.init(frame: .zero)
        toolTip = title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        let size = Settings.shared.dotSize.points
        return NSSize(width: size, height: size)
    }

    override var mouseDownCanMoveWindow: Bool { true }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)

        switch style {
        case .color(let color):
            fillDot(in: rect, color: color)
        case .symbol(let glyph, let color):
            fillDot(in: rect, color: color)
            drawGlyph(glyph, in: rect)
        case .adaptiveFilled:
            fillDot(in: rect, color: .labelColor)
        case .adaptiveHollow:
            let path = NSBezierPath(ovalIn: rect.insetBy(dx: 0.75, dy: 0.75))
            path.lineWidth = 1.5
            NSColor.labelColor.setStroke()
            path.stroke()
        case .image(let image):
            image.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1)
        }
    }

    private func fillDot(in rect: NSRect, color: NSColor) {
        let path = NSBezierPath(ovalIn: rect)
        color.setFill()
        path.fill()
        // Hairline edge so light dots stay visible over light backgrounds.
        NSColor.black.withAlphaComponent(0.2).setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    private func drawGlyph(_ glyph: String, in rect: NSRect) {
        let text = NSAttributedString(string: glyph, attributes: [
            .font: NSFont.systemFont(ofSize: rect.height * 0.7, weight: .bold),
            .foregroundColor: NSColor.white,
        ])
        let size = text.size()
        text.draw(at: NSPoint(x: rect.midX - size.width / 2,
                              y: rect.midY - size.height / 2))
    }
}
