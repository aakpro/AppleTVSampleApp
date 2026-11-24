// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SampleTVPlaybackProgress",
    platforms: [.tvOS(.v17)],
    products: [
        .library(name: "SampleTVPlaybackProgress", targets: ["SampleTVPlaybackProgress"])
    ],
    dependencies: [
        .package(name: "SampleTVDomain", path: "../SampleTVDomain"),
    ],
    targets: [
        .target(
            name: "SampleTVPlaybackProgress",
            dependencies: [
                .product(name: "SampleTVDomain", package: "SampleTVDomain"),
            ]
        )
    ]
)