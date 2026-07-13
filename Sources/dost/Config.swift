import Foundation

struct PortSpec {
    let port: UInt16
    let title: String?
}

struct ConfigError: Error, CustomStringConvertible {
    let description: String
}

struct Config {
    static let version = "1.2.1"

    static let defaultPorts = [PortSpec(port: 1738, title: nil)]

    var portsOverride: [PortSpec]?
    var initialStyle = "white"
    var orientationOverride: Orientation?
    var spacingOverride: Spacing?
    var dotSizeOverride: DotSize?

    static let usage = """
    dost \(version) — AnyBar-style status indicators in a floating window

    USAGE: dost [options]

    OPTIONS:
      -p, --ports LIST       Comma-separated UDP ports, each with an optional
                             :title used as tooltip (default: 1738)
                             e.g. --ports 1738:build,1739:tests
                             (persisted across launches; dots can also be
                             added/removed from the right-click menu)
      -o, --orientation DIR  How indicators stack: vertical | horizontal
                             (persisted across launches)
      -s, --spacing MODE     Gap between indicators: cozy | regular | tight
                             (persisted across launches)
      -z, --size SIZE        Dot size: small | medium | big
                             (persisted across launches)
          --init NAME        Initial style for every indicator (default: white)
      -h, --help             Show this help
          --version          Show version

    ENVIRONMENT:
      DOST_PORTS             Same format as --ports
      DOST_INIT              Same as --init
      ANYBAR_PORT            Single port, for AnyBar drop-in compatibility
      ANYBAR_TITLE           Tooltip when running a single indicator
      ANYBAR_INIT            Same as --init

    API (identical to AnyBar):
      echo -n "red" | nc -4u -w0 localhost 1738

      Messages: white red orange yellow green cyan blue purple black
                question exclamation filled hollow quit
      Custom:   drop NAME.png (19x19) / NAME@2x.png (38x38) into ~/.dost
                (or ~/.AnyBar) and send NAME
    """

    static func parse(arguments: [String], environment: [String: String]) throws -> Config {
        var config = Config()

        if let env = environment["DOST_PORTS"] {
            config.portsOverride = try parsePorts(env)
        } else if let env = environment["ANYBAR_PORT"] {
            guard let port = UInt16(env) else {
                throw ConfigError(description: "invalid ANYBAR_PORT: \(env)")
            }
            config.portsOverride = [PortSpec(port: port, title: environment["ANYBAR_TITLE"])]
        } else if let title = environment["ANYBAR_TITLE"] {
            config.portsOverride = [PortSpec(port: 1738, title: title)]
        }

        if let env = environment["DOST_INIT"] ?? environment["ANYBAR_INIT"] {
            config.initialStyle = env
        }

        var args = arguments.dropFirst().makeIterator()
        while let arg = args.next() {
            switch arg {
            case "-p", "--ports":
                config.portsOverride = try parsePorts(try value(for: arg, from: &args))
            case "-o", "--orientation":
                let raw = try value(for: arg, from: &args)
                guard let orientation = Orientation(rawValue: raw) else {
                    throw ConfigError(description: "invalid orientation: \(raw) (use vertical or horizontal)")
                }
                config.orientationOverride = orientation
            case "-s", "--spacing":
                let raw = try value(for: arg, from: &args)
                guard let spacing = Spacing(rawValue: raw) else {
                    throw ConfigError(description: "invalid spacing: \(raw) (use cozy, regular or tight)")
                }
                config.spacingOverride = spacing
            case "-z", "--size":
                let raw = try value(for: arg, from: &args)
                guard let size = DotSize(rawValue: raw) else {
                    throw ConfigError(description: "invalid size: \(raw) (use small, medium or big)")
                }
                config.dotSizeOverride = size
            case "--init":
                config.initialStyle = try value(for: arg, from: &args)
            case "-h", "--help":
                print(usage)
                exit(0)
            case "--version":
                print("dost \(version)")
                exit(0)
            default:
                throw ConfigError(description: "unknown option: \(arg)\n\n\(usage)")
            }
        }

        return config
    }

    private static func value(for flag: String, from args: inout IndexingIterator<Array<String>.SubSequence>) throws -> String {
        guard let value = args.next() else {
            throw ConfigError(description: "missing value for \(flag)")
        }
        return value
    }

    static func serializePorts(_ specs: [PortSpec]) -> String {
        specs.map { spec in
            spec.title.map { "\(spec.port):\($0)" } ?? "\(spec.port)"
        }.joined(separator: ",")
    }

    static func parsePorts(_ list: String) throws -> [PortSpec] {
        let specs = try list.split(separator: ",").map { entry -> PortSpec in
            let parts = entry.split(separator: ":", maxSplits: 1)
            guard let first = parts.first, let port = UInt16(first) else {
                throw ConfigError(description: "invalid port: \(entry)")
            }
            let title = parts.count > 1 ? String(parts[1]) : nil
            return PortSpec(port: port, title: title)
        }
        guard !specs.isEmpty else {
            throw ConfigError(description: "no ports given")
        }
        guard Set(specs.map(\.port)).count == specs.count else {
            throw ConfigError(description: "duplicate ports in: \(list)")
        }
        return specs
    }
}
