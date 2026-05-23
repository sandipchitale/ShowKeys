// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ShowKeys",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ShowKeys",
            path: "Sources/ShowKeys"
        )
    ]
)
