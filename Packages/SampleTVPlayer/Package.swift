// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SampleTVPlayer",
    platforms: [.tvOS(.v17)],
    products: [
        .library(name: "SampleTVPlayer", targets: ["SampleTVPlayer"])
    ],
    targets: [
        .target(name: "SampleTVPlayer")
    ]
)
