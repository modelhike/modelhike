// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "modelhike-smart-cli",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "ModelHikeKit", targets: ["ModelHikeKit"]),
        .executable(name: "modelhike", targets: ["ModelHikeCLI"]),
        .executable(name: "modelhike-mcp", targets: ["ModelHikeMCP"]),
        .executable(name: "DevTester_MCP", targets: ["DevTester_MCP"]),
    ],
    dependencies: [
        .package(url: "https://github.com/modelhike/modelhike-lib.git", branch: "main"),
        .package(url: "https://github.com/modelhike/modelhike-blueprints.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.7.1"),
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.12.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.11.0"),
    ],
    targets: [
        .target(
            name: "ModelHikeKit",
            dependencies: [
                .product(name: "ModelHike", package: "modelhike-lib"),
                .product(name: "ModelHike.Blueprints", package: "modelhike-blueprints"),
            ],
            path: "Sources/ModelHikeKit"
        ),
        .executableTarget(
            name: "ModelHikeCLI",
            dependencies: [
                "ModelHikeKit",
                .product(name: "ModelHike", package: "modelhike-lib"),
                .product(name: "ModelHike.Blueprints", package: "modelhike-blueprints"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/CLI"
        ),
        .executableTarget(
            name: "ModelHikeMCP",
            dependencies: [
                "ModelHikeKit",
                .product(name: "ModelHike", package: "modelhike-lib"),
                .product(name: "ModelHike.Blueprints", package: "modelhike-blueprints"),
                .product(name: "MCP", package: "swift-sdk"),
            ],
            path: "Sources/MCP"
        ),
        .executableTarget(
            name: "DevTester_MCP",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "DevTester_MCP/Sources"
        ),
        .testTarget(
            name: "ModelHikeKitTests",
            dependencies: [
                "ModelHikeKit",
                .product(name: "ModelHike", package: "modelhike-lib"),
            ],
            path: "Tests/ModelHikeKitTests"
        ),
    ]
)
