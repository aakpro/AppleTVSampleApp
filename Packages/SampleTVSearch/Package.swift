// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SampleTVSearch",
    platforms: [.tvOS(.v17)],
    products: [
        .library(name: "SampleTVSearch", targets: ["SampleTVSearch"])
    ],
    dependencies: [
        .package(path: "../SampleTVDomain"),
        .package(path: "../SampleTVUI")
    ],
    targets: [
        .target(
            name: "SampleTVSearch",
            dependencies: [
                .product(name: "SampleTVDomain", package: "SampleTVDomain"),
                .product(name: "SampleTVUI", package: "SampleTVUI")
            ]
        ),
        .testTarget(
            name: "SampleTVSearchTests",
            dependencies: ["SampleTVSearch"]
        )
    ]
)