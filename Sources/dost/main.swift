import AppKit

let config: Config
do {
    config = try Config.parse(
        arguments: CommandLine.arguments,
        environment: ProcessInfo.processInfo.environment
    )
} catch {
    FileHandle.standardError.write(Data("dost: \(error)\n".utf8))
    exit(1)
}

let app = NSApplication.shared
let delegate = AppDelegate(config: config)
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
