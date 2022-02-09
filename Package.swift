// swift-tools-version:5.3.0

import PackageDescription

let package = Package(
    name: "Wording",
    platforms: [
        .iOS("15")
    ],
    products: [
        .library(
            name: "WordingManager",
            targets: [
                "WordingManager"
            ]
        ),
        .library(
            name: "Wording",
            targets: [
                "Wording"
            ]
        )
    ],
    dependencies: [
        .package(name: "Core", url: "https://github.com/kutchie-pelaez-packages/Core.git", .branch("master")),
        .package(name: "Localization", url: "https://github.com/kutchie-pelaez-packages/Localization.git", .branch("master")),
        .package(name: "Logging", url: "https://github.com/kutchie-pelaez-packages/Logging.git", .branch("master")),
        .package(name: "PathKit", url: "https://github.com/kylef/PathKit.git", from: "1.0.0"),
        .package(name: "SwiftCLI", url: "https://github.com/jakeheis/SwiftCLI.git", from: "6.0.0"),
        .package(name: "Yams", url: "https://github.com/jpsim/Yams.git", from: "4.0.6")
    ],
    targets: [
        .target(
            name: "WordingManager",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Language", package: "Localization"),
                .product(name: "LocalizationManager", package: "Localization"),
                .product(name: "Logger", package: "Logging"),
                .target(name: "Wording")
            ]
        ),
        .target(
            name: "Wording",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Yams", package: "Yams")
            ]
        ),
        .target(
            name: "WordingGenerator",
            dependencies: [
                .product(name: "PathKit", package: "PathKit"),
                .product(name: "SwiftCLI", package: "SwiftCLI"),
                .product(name: "Yams", package: "Yams")
            ]
        )
    ]
)
