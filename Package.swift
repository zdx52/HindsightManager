// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "HindsightManager",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "HindsightManager"
        ),
        .testTarget(
            name: "HindsightManagerTests",
            dependencies: ["HindsightManager"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
