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
    dependencies: [
        .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.12.0")
    ],
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
                "NovaCoachApp",
                "Quick",
                "Nimble"
            ],
            path: "Tests/NovaCoachAppTests"
        )
    ]
)
