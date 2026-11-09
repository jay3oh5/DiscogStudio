// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DiscogStudio",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "DiscogStudio", targets: ["DiscogStudio"])
    ],
    targets: [
        .executableTarget(
            name: "DiscogStudio",
            path: "Sources"
        )
    ]
)
