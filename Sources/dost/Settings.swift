import AppKit

enum Orientation: String, CaseIterable {
    case vertical
    case horizontal
}

enum DotSize: String, CaseIterable {
    case small
    case medium
    case big

    var points: CGFloat {
        switch self {
        case .small: return 11
        case .medium: return 15
        case .big: return 19
        }
    }
}

enum Spacing: String, CaseIterable {
    case cozy
    case regular
    case tight

    var points: CGFloat {
        switch self {
        case .regular: return 10
        case .cozy: return 6
        case .tight: return 2
        }
    }
}

/// Persisted user preferences. A dedicated suite keeps the domain stable
/// whether dost runs as a bare executable or inside an app bundle.
final class Settings {
    static let shared = Settings()

    private let defaults = UserDefaults(suiteName: "dev.danielfilho.dost.settings")!

    private enum Key {
        static let orientation = "orientation"
        static let spacing = "spacing"
        static let dotSize = "dotSize"
        static let originX = "windowOriginX"
        static let originY = "windowOriginY"
    }

    var orientation: Orientation {
        get { defaults.string(forKey: Key.orientation).flatMap(Orientation.init) ?? .vertical }
        set { defaults.set(newValue.rawValue, forKey: Key.orientation) }
    }

    var spacing: Spacing {
        get { defaults.string(forKey: Key.spacing).flatMap(Spacing.init) ?? .regular }
        set { defaults.set(newValue.rawValue, forKey: Key.spacing) }
    }

    var dotSize: DotSize {
        get { defaults.string(forKey: Key.dotSize).flatMap(DotSize.init) ?? .big }
        set { defaults.set(newValue.rawValue, forKey: Key.dotSize) }
    }

    var windowOrigin: NSPoint? {
        get {
            guard defaults.object(forKey: Key.originX) != nil,
                  defaults.object(forKey: Key.originY) != nil else { return nil }
            return NSPoint(x: defaults.double(forKey: Key.originX),
                           y: defaults.double(forKey: Key.originY))
        }
        set {
            guard let origin = newValue else {
                defaults.removeObject(forKey: Key.originX)
                defaults.removeObject(forKey: Key.originY)
                return
            }
            defaults.set(origin.x, forKey: Key.originX)
            defaults.set(origin.y, forKey: Key.originY)
        }
    }
}
