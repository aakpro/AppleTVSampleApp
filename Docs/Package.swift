// SampleTV - Main Package Manifest
// Dependencies: SwiftInject, Clippy Checks, Local SPM Structure  
// Version Control: GitHub Flow + CI/CD Pipeline

package.swift-version = 5.9

dependencies: [
    .Package(url: "https://github.com/apple/swift-syntax", majorVersion: 5),
]

targets: [    
    .target(
        name: "sampletv-app",
        dependencies: [
            .product(name: "DependencyInjection", package: "SwiftInject"),
        ]
    ),
    
    .target(
        name: "DIContainer",
        dependencies: [
            /// API Layer Dependencies (if present)  
            .product(name: "sampletv-api", package: "sampletv-api-swift-package"),
        ]
    ),
    
    .executableTarget(
        name: "SampleTV-App",
        sources: [
            "Sources/AppEntry.swift" 
        ],  
    ),
]
