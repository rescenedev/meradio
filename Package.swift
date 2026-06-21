// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "meradio",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "meradio",
            resources: [
                .process("Resources/stations.json")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
