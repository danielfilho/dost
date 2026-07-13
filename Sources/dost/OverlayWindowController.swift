import AppKit

/// Borderless transparent window that floats above everything, joins all
/// Spaces, and can be dragged anywhere. Its position is persisted.
final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

final class ContainerView: NSView {
    var menuProvider: (() -> NSMenu)?

    override var mouseDownCanMoveWindow: Bool { true }

    override func menu(for event: NSEvent) -> NSMenu? {
        menuProvider?()
    }
}

final class OverlayWindowController: NSObject, NSWindowDelegate {
    private static let padding: CGFloat = 6
    private static let screenMargin: CGFloat = 12

    let window: OverlayWindow
    private let stack = NSStackView()
    private let container = ContainerView()
    private let settings = Settings.shared
    private var dots: [Dot]
    private let initialStyle: String

    init(dots: [Dot], initialStyle: String) {
        self.dots = dots
        self.initialStyle = initialStyle
        window = OverlayWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        super.init()

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        window.isMovableByWindowBackground = true
        window.delegate = self

        stack.translatesAutoresizingMaskIntoConstraints = false
        dots.forEach { stack.addArrangedSubview($0.view) }

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: Self.padding),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Self.padding),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Self.padding),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Self.padding),
        ])
        window.contentView = container
        container.menuProvider = { [weak self] in self?.buildMenu() ?? NSMenu() }

        applyLayout()
        positionWindow()
        window.orderFrontRegardless()
    }

    // MARK: - Layout

    private func applyLayout() {
        stack.orientation = settings.orientation == .horizontal ? .horizontal : .vertical
        stack.spacing = settings.spacing.points
        stack.arrangedSubviews.forEach { $0.invalidateIntrinsicContentSize() }

        let size = container.fittingSize
        var frame = window.frame
        let topLeft = NSPoint(x: frame.minX, y: frame.maxY)
        frame.size = size
        frame.origin = NSPoint(x: topLeft.x, y: topLeft.y - size.height)
        window.setFrame(frame, display: true)
    }

    private func positionWindow() {
        if let saved = settings.windowOrigin {
            let frame = NSRect(origin: saved, size: window.frame.size)
            let visible = NSScreen.screens.contains { $0.visibleFrame.intersects(frame) }
            if visible {
                window.setFrameOrigin(saved)
                return
            }
        }
        // Default: near the top-right corner, where menubar dots would live.
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        window.setFrameOrigin(NSPoint(
            x: visible.maxX - window.frame.width - Self.screenMargin,
            y: visible.maxY - window.frame.height - Self.screenMargin
        ))
    }

    func windowDidMove(_ notification: Notification) {
        settings.windowOrigin = window.frame.origin
    }

    // MARK: - Context menu

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let orientationTitle = NSMenuItem(title: "Stack", action: nil, keyEquivalent: "")
        orientationTitle.isEnabled = false
        menu.addItem(orientationTitle)
        for orientation in Orientation.allCases {
            let item = NSMenuItem(title: orientation.rawValue.capitalized,
                                  action: #selector(selectOrientation(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.representedObject = orientation.rawValue
            item.state = settings.orientation == orientation ? .on : .off
            item.indentationLevel = 1
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let spacingTitle = NSMenuItem(title: "Spacing", action: nil, keyEquivalent: "")
        spacingTitle.isEnabled = false
        menu.addItem(spacingTitle)
        for spacing in Spacing.allCases {
            let item = NSMenuItem(title: spacing.rawValue.capitalized,
                                  action: #selector(selectSpacing(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.representedObject = spacing.rawValue
            item.state = settings.spacing == spacing ? .on : .off
            item.indentationLevel = 1
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let sizeTitle = NSMenuItem(title: "Size", action: nil, keyEquivalent: "")
        sizeTitle.isEnabled = false
        menu.addItem(sizeTitle)
        for size in DotSize.allCases {
            let item = NSMenuItem(title: size.rawValue.capitalized,
                                  action: #selector(selectSize(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.representedObject = size.rawValue
            item.state = settings.dotSize == size ? .on : .off
            item.indentationLevel = 1
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let add = NSMenuItem(title: "Add Dot…", action: #selector(promptAddDot), keyEquivalent: "")
        add.target = self
        menu.addItem(add)

        let remove = NSMenuItem(title: "Remove Dot", action: nil, keyEquivalent: "")
        if dots.count > 1 {
            let submenu = NSMenu()
            for dot in dots {
                let label = dot.title.map { "\($0) — port \(dot.port)" } ?? "port \(dot.port)"
                let item = NSMenuItem(title: label, action: #selector(removeDot(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = dot.port
                submenu.addItem(item)
            }
            remove.submenu = submenu
        }
        menu.addItem(remove)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)

        return menu
    }

    // MARK: - Add / remove dots

    @objc private func promptAddDot() {
        let alert = NSAlert()
        alert.messageText = "Add Dot"
        alert.informativeText = "The dot listens for AnyBar-style messages on the given UDP port."
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")

        let portField = NSTextField(frame: NSRect(x: 0, y: 30, width: 220, height: 22))
        portField.placeholderString = "Port (e.g. 1739)"
        let nameField = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 22))
        nameField.placeholderString = "Name (optional)"
        portField.nextKeyView = nameField
        nameField.nextKeyView = portField

        let accessory = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 52))
        accessory.addSubview(portField)
        accessory.addSubview(nameField)
        alert.accessoryView = accessory
        alert.window.initialFirstResponder = portField

        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let portText = portField.stringValue.trimmingCharacters(in: .whitespaces)
        guard let port = UInt16(portText), port > 0 else {
            showError("\"\(portText)\" is not a valid port (1–65535).")
            return
        }
        guard !dots.contains(where: { $0.port == port }) else {
            showError("There is already a dot on port \(port).")
            return
        }
        // Commas would break the persisted port-list format.
        let name = nameField.stringValue
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)

        do {
            let dot = try Dot(port: port, title: name.isEmpty ? nil : name, initialStyle: initialStyle)
            dots.append(dot)
            stack.addArrangedSubview(dot.view)
            persistDots()
            applyLayout()
        } catch {
            showError("\(error)")
        }
    }

    @objc private func removeDot(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? UInt16,
              let index = dots.firstIndex(where: { $0.port == port }),
              dots.count > 1 else { return }
        let dot = dots.remove(at: index)
        stack.removeArrangedSubview(dot.view)
        dot.view.removeFromSuperview()
        persistDots()
        applyLayout()
    }

    private func persistDots() {
        settings.ports = dots.map(\.spec)
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "dost"
        alert.informativeText = message
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc private func selectOrientation(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let orientation = Orientation(rawValue: raw) else { return }
        settings.orientation = orientation
        applyLayout()
    }

    @objc private func selectSpacing(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let spacing = Spacing(rawValue: raw) else { return }
        settings.spacing = spacing
        applyLayout()
    }

    @objc private func selectSize(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let size = DotSize(rawValue: raw) else { return }
        settings.dotSize = size
        applyLayout()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
