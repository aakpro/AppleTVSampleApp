// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SampleTVProfile",
    platforms: [.tvOS(.v17)],
    products: [
        .library(
            name: "SampleTVProfile",
            targets: ["SampleTVProfile"]
        )
    ],
    dependencies: [
        .package(path: "../SampleTVDomain"),
        .package(path: "../SampleTVUI")
    ],
    targets: [
        .target(
            name: "SampleTVProfile",
            dependencies: [
                .product(name: "SampleTVDomain", package: "SampleTVDomain"),
                .product(name: "SampleTVUI", package: "SampleTVUI")
            ]
        ),
        .testTarget(
            name: "SampleTVProfileTests",
            dependencies: [
                "SampleTVProfile",
                .product(name: "SampleTVDomain", package: "SampleTVDomain")
            ]
        )
    ]
)
