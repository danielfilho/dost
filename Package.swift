// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "dost",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "dost",
            path: "Sources/dost"
        )
    ]
)
