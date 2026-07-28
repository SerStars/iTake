// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "iTake",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "iTake",
            path: "Sources/iTake",
            resources: [
                .copy("Resources/languages.json")
            ]
        )
    ]
)
