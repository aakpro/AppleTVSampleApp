// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SampleTVDiscovery",
    platforms: [.tvOS(.v17)],
    products: [
        .library(name: "SampleTVDiscovery", targets: ["SampleTVDiscovery"])
    ],
    dependencies: [
        .package(path: "../SampleTVDomain"),
        .package(path: "../SampleTVUI")
    ],
    targets: [
        .target(
            name: "SampleTVDiscovery",
            dependencies: [
                .product(name: "SampleTVDomain", package: "SampleTVDomain"),
                .product(name: "SampleTVUI", package: "SampleTVUI")
            ]
        ),
        .testTarget(
            name: "SampleTVDiscoveryTests",
            dependencies: ["SampleTVDiscovery"]
        )
    ]
)
