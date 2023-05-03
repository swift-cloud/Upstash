// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "Upstash",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(name: "Upstash", targets: ["Upstash"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-cloud/Compute", from: "2.0.0"),
        .package(url: "https://github.com/flight-school/anycodable", from: "0.6.7")
    ],
    targets: [
        .target(name: "Upstash", dependencies: ["Compute", .product(name: "AnyCodable", package: "anycodable")])
    ]
)
