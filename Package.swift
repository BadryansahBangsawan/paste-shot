// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PasteShot",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "PasteShot", targets: ["PasteShot"])
    ],
    targets: [
        .executableTarget(name: "PasteShot", path: "Sources")
    ]
)
