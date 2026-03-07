// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ModelHike",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "ModelHike", targets: ["ModelHike"]),
        .executable(name: "DevTester", targets: ["DevTester"])
    ],
    targets: [
        .target(
            name: "ModelHike",
            path: "Sources",
            exclude: [
                "_Common_/ThirdParty/Codextended/LICENSE",
                "_Common_/ThirdParty/Codextended/README.md"
            ],
            swiftSettings: [
                //.unsafeFlags([
                //    //"-Xfrontend", "-strict-concurrency=complete",
                //    "-Xfrontend", "-warn-long-function-bodies=200",
                //    "-Xfrontend", "-warn-long-expression-type-checking=200"]
                //)
            ]
        ),
        .executableTarget(
            name: "DevTester",
            dependencies: ["ModelHike"],
            path: "DevTester",
            resources: [.process("Assets")]
        ),
        .testTarget(
            name: "ModelHikeTests",
            dependencies: ["ModelHike"],
            path: "Tests"
        ),
    ]
)
