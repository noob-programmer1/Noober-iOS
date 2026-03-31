// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Noober",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(
            name: "Noober",
            targets: ["Noober"]
        ),
        .library(
            name: "NooberShared",
            targets: ["NooberShared"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Noober",
            dependencies: [],
            path: "Sources/Noober",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "NooberShared",
            dependencies: [],
            path: "Sources/NooberShared"
        ),
        .testTarget(
            name: "NooberTests",
            dependencies: ["Noober"],
            path: "Tests/NooberTests"
        )
    ]
)
