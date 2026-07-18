// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "iTake",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "iTake",
            path: "Sources/iTake"
        )
    ]
)
