// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Upstash",
    platforms: [
        .macOS(.v11),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v9),
        .driverKit(.v22),
        .macCatalyst(.v13)
    ],
    products: [
        .library(name: "Upstash", targets: ["Upstash"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-cloud/Compute", from: "2.0.0")
    ],
    targets: [
        .target(name: "Upstash", dependencies: ["Compute"])
    ]
)
