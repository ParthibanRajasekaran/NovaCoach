// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "NovaCoach",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "NovaCoachApp",
            targets: ["NovaCoachApp"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NovaCoachApp",
            dependencies: [],
            path: "Sources/NovaCoachApp",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .define("ENABLE_SQLCIPHER", .when(platforms: [.iOS]))
            ]
        ),
        .testTarget(
            name: "NovaCoachAppTests",
            dependencies: [
                "NovaCoachApp"
            ],
            path: "Tests/NovaCoachAppTests"
        )
    ]
)
