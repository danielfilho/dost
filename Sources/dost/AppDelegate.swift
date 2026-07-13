import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let config: Config
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
        if let dotSize = config.dotSizeOverride {
            settings.dotSize = dotSize
        }
        if let ports = config.portsOverride {
            settings.ports = ports
        }

        let specs = settings.ports ?? Config.defaultPorts
        var dots: [Dot] = []
        for spec in specs {
            do {
                dots.append(try Dot(port: spec.port, title: spec.title, initialStyle: config.initialStyle))
            } catch {
                FileHandle.standardError.write(Data("dost: \(error)\n".utf8))
            }
        }

        guard !dots.isEmpty else {
            FileHandle.standardError.write(Data("dost: no port could be bound, exiting\n".utf8))
            exit(1)
        }

        controller = OverlayWindowController(dots: dots, initialStyle: config.initialStyle)
    }
}
