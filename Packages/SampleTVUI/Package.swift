// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SampleTVUI",
    platforms: [.tvOS(.v17)],
    products: [
        .library(name: "SampleTVUI", targets: ["SampleTVUI"])
    ],
    dependencies: [
        .package(path: "../SampleTVDomain")
    ],
    targets: [
        .target(
            name: "SampleTVUI",
            dependencies: [.product(name: "SampleTVDomain", package: "SampleTVDomain")]
        ),
        .testTarget(
            name: "SampleTVUITests",
            dependencies: ["SampleTVUI"]
        )
    ]
)
