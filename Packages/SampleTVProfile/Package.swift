// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SampleTVProfile",
    platforms: [.tvOS(.v17)],
    products: [
        .library(
            name: "SampleTVProfile",
            targets: ["SampleTVProfile"]),
    ],
    dependencies: [
        .package(path: "../SampleTVDomain"),
        .package(path: "../SampleTVUI"),
        .package(path: "../SampleTVPlaybackProgress"),
    ],
    targets: [
        .target(
            name: "SampleTVProfile",
            dependencies: [
                .product(name: "SampleTVDomain", package: "SampleTVDomain"),
                .product(name: "SampleTVUI", package: "SampleTVUI"),
                .product(name: "SampleTVPlaybackProgress", package: "SampleTVPlaybackProgress"),
            ]),
        .testTarget(
            name: "SampleTVProfileTests",
            dependencies: [
                .target(name: "SampleTVProfile"),
                .product(name: "SampleTVDomain", package: "SampleTVDomain"),
            ]),
    ]
)