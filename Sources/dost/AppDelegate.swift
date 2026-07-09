import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let config: Config
    private var servers: [UDPServer] = []
    private var controller: OverlayWindowController?

    init(config: Config) {
        self.config = config
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = Settings.shared
        if let orientation = config.orientationOverride {
            settings.orientation = orientation
        }
        if let spacing = config.spacingOverride {
            settings.spacing = spacing
        }

        let initialStyle = IndicatorStyle.resolve(config.initialStyle) ?? .color(.white)
        let indicators = config.ports.map { spec in
            IndicatorView(title: spec.title ?? "port \(spec.port)", style: initialStyle)
        }

        for (spec, view) in zip(config.ports, indicators) {
            do {
                let server = try UDPServer(port: spec.port) { [weak view] message in
                    if message == "quit" {
                        NSApp.terminate(nil)
                        return
                    }
                    guard let style = IndicatorStyle.resolve(message) else {
                        FileHandle.standardError.write(Data("dost: unknown message \"\(message)\" on port \(spec.port)\n".utf8))
                        return
                    }
                    view?.style = style
                }
                servers.append(server)
            } catch {
                FileHandle.standardError.write(Data("dost: \(error)\n".utf8))
            }
        }

        guard !servers.isEmpty else {
            FileHandle.standardError.write(Data("dost: no port could be bound, exiting\n".utf8))
            exit(1)
        }

        controller = OverlayWindowController(indicators: indicators)
    }
}
