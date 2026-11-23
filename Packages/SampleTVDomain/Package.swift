// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SampleTVDomain",
    platforms: [.tvOS(.v17)],
    products: [
        .library(name: "SampleTVDomain", targets: ["SampleTVDomain"])
    ],
    targets: [
        .target(name: "SampleTVDomain"),
        .testTarget(
            name: "SampleTVDomainTests",
            dependencies: ["SampleTVDomain"]
        )
    ]
)
