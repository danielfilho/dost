import AppKit

enum IndicatorStyle {
    case color(NSColor)
    case symbol(String, NSColor)
    /// Follows the system appearance: dark dot in light mode, light dot in dark mode.
    case adaptiveFilled
    case adaptiveHollow
    case image(NSImage)

    static func resolve(_ name: String) -> IndicatorStyle? {
        switch name {
        case "white": return .color(.white)
        case "red": return .color(.systemRed)
        case "orange": return .color(.systemOrange)
        case "yellow": return .color(.systemYellow)
        case "green": return .color(.systemGreen)
        case "cyan": return .color(.systemCyan)
        case "blue": return .color(.systemBlue)
        case "purple": return .color(.systemPurple)
        case "black": return .color(.black)
        case "question": return .symbol("?", .systemGray)
        case "exclamation": return .symbol("!", .systemOrange)
        case "filled": return .adaptiveFilled
        case "hollow": return .adaptiveHollow
        default: return customImage(named: name).map(IndicatorStyle.image)
        }
    }

    /// Looks for NAME@2x.png / NAME.png in ~/.dost, falling back to ~/.AnyBar
    /// so existing AnyBar image sets keep working.
    private static func customImage(named name: String) -> NSImage? {
        guard !name.contains("/") else { return nil }
        let directories = ["~/.dost", "~/.AnyBar"].map(NSString.init(string:))
        for directory in directories {
            for file in ["\(name)@2x.png", "\(name).png"] {
                let path = directory.appendingPathComponent(file) as String
                let expanded = NSString(string: path).expandingTildeInPath
                if let image = NSImage(contentsOfFile: expanded) {
                    return image
                }
            }
        }
        return nil
    }
}
