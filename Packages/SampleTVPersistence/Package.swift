// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SampleTVPersistence",
    platforms: [.tvOS(.v17)],
    products: [
        .library(
            name: "SampleTVPersistence",
            targets: ["SampleTVPersistence"]
        )
    ],
    dependencies: [
        .package(path: "../SampleTVDomain")
    ],
    targets: [
        .target(
            name: "SampleTVPersistence",
            dependencies: [
                .product(name: "SampleTVDomain", package: "SampleTVDomain")
            ]
        ),
        .testTarget(
            name: "SampleTVPersistenceTests",
            dependencies: [
                "SampleTVPersistence",
                .product(name: "SampleTVDomain", package: "SampleTVDomain")
            ]
        )
    ]
)
