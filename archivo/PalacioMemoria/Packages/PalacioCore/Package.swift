// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PalacioCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "PalacioCore", targets: ["PalacioCore"]),
    ],
    targets: [
        .target(name: "PalacioCore"),
        .testTarget(name: "PalacioCoreTests", dependencies: ["PalacioCore"]),
    ]
)
