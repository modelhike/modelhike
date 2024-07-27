// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DiagSoup",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "DiagSoup", targets: ["DiagSoup"]),
        .executable(name: "DevTester", targets: ["DevTester"])
    ],
    targets: [
        .target(
            name: "DiagSoup",
            path: "Sources",
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
            dependencies: ["DiagSoup"],
            path: "DevTester"
        ),
        .testTarget(
            name: "DiagSoupTests",
            dependencies: ["DiagSoup"],
            path: "Tests"
        ),
    ]
)
