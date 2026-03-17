// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Noober",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "Noober",
            targets: ["Noober"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Noober",
            dependencies: [],
            path: "Sources/Noober"
        ),
        .testTarget(
            name: "NooberTests",
            dependencies: ["Noober"],
            path: "Tests/NooberTests"
        )
    ]
)
