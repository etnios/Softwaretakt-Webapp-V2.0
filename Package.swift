// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "Softwaretakt",
    platforms: [
        .iOS(.v15),
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "SoftwaretaktApp",
            targets: ["Softwaretakt"])
    ],
    dependencies: [
        // AudioKit for professional audio
        .package(url: "https://github.com/AudioKit/AudioKit", from: "5.6.0"),
        .package(url: "https://github.com/AudioKit/AudioKitEX", from: "5.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "Softwaretakt",
            dependencies: [
                "AudioKit",
                "AudioKitEX",
            ],
            path: "Sources/Softwaretakt",
            exclude: ["AudioUnit/Info.plist", "App/Info.plist"],
            resources: [.process("Resources")]),
        .testTarget(
            name: "SoftwaretaktTests",
            dependencies: ["Softwaretakt"],
            path: "Tests")
    ]
)
