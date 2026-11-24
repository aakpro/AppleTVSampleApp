// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SampleTVAPI",
    platforms: [.tvOS(.v17)],
    products: [
        .library(name: "SampleTVAPI", targets: ["SampleTVAPI"])
    ],
    dependencies: [
        .package(path: "../SampleTVDomain")
    ],
    targets: [
        .target(
            name: "SampleTVAPI",
            dependencies: [.product(name: "SampleTVDomain", package: "SampleTVDomain")]
        ),
        .testTarget(
            name: "SampleTVAPITests",
            dependencies: ["SampleTVAPI"]
        )
    ]
)
