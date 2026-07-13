import AppKit

/// One indicator: the dot view plus the UDP server driving it. Owns the
/// tooltip, which shows the title (if any), the port, and the current style
/// name. Releasing a Dot closes its socket.
final class Dot {
    let port: UInt16
    let title: String?
    let view: IndicatorView

    private var server: UDPServer?
    private var styleName: String

    var spec: PortSpec { PortSpec(port: port, title: title) }

    init(port: UInt16, title: String?, initialStyle: String) throws {
        self.port = port
        self.title = title

        let resolved = IndicatorStyle.resolve(initialStyle)
        self.styleName = resolved == nil ? "white" : initialStyle
        self.view = IndicatorView(tooltip: "", style: resolved ?? .color(.white))
        updateTooltip()

        self.server = try UDPServer(port: port) { [weak self] message in
            self?.handle(message)
        }
    }

    private func handle(_ message: String) {
        if message == "quit" {
            NSApp.terminate(nil)
            return
        }
        guard let style = IndicatorStyle.resolve(message) else {
            FileHandle.standardError.write(Data("dost: unknown message \"\(message)\" on port \(port)\n".utf8))
            return
        }
        view.style = style
        styleName = message
        updateTooltip()
    }

    private func updateTooltip() {
        var parts: [String] = []
        if let title, !title.isEmpty {
            parts.append(title)
        }
        parts.append("port \(port)")
        parts.append(styleName)
        view.toolTip = parts.joined(separator: " — ")
    }
}
