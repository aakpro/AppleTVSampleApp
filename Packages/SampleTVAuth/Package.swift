// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SampleTVAuth",
    platforms: [.tvOS(.v17)],
    products: [
        .library(
            name: "SampleTVAuth",
            targets: ["SampleTVAuth"]),
    ],
    dependencies: [
        .package(path: "../SampleTVDomain"),
        .package(path: "../SampleTVUI"),
    ],
    targets: [
        .target(
            name: "SampleTVAuth",
            dependencies: [
                .product(name: "SampleTVDomain", package: "SampleTVDomain"),
                .product(name: "SampleTVUI", package: "SampleTVUI"),
            ]),
        .testTarget(
            name: "SampleTVAuthTests",
            dependencies: [
                .target(name: "SampleTVAuth"),
                .product(name: "SampleTVDomain", package: "SampleTVDomain"),
            ]),
    ]
)