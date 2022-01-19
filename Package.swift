// swift-tools-version:5.3.0

import PackageDescription

let package = Package(
    name: "WordingManager",
    platforms: [
        .iOS("15")
    ],
    products: [
        .library(name: "WordingManager", targets: ["WordingManager"]),
        .library(name: "Wording", targets: ["Wording"])
    ],
    dependencies: [
        .package(name: "LocalizationManager", url: "https://github.com/kutchie-pelaez-packages/LocalizationManager", .branch("master")),
        .package(name: "CoreUtils", url: "https://github.com/kutchie-pelaez-packages/CoreUtils", .branch("master")),
        .package(name: "Yams", url: "https://github.com/jpsim/Yams.git", from: "4.0.6"),
        .package(name: "PathKit", url: "https://github.com/kylef/PathKit.git", from: "1.0.0"),
        .package(name: "SwiftCLI", url: "https://github.com/jakeheis/SwiftCLI.git", from: "6.0.0")
    ],
    targets: [
        .target(
            name: "WordingManager",
            dependencies: [
                .product(name: "LocalizationManager", package: "LocalizationManager"),
                .product(name: "Language", package: "LocalizationManager"),
                .product(name: "CoreUtils", package: "CoreUtils"),
                .target(name: "Wording")
            ]
        ),
        .target(
            name: "WordingGenerator",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
                .product(name: "PathKit", package: "PathKit"),
                .product(name: "SwiftCLI", package: "SwiftCLI")
            ]
        ),
        .target(
            name: "Wording",
            dependencies: [
                .product(name: "CoreUtils", package: "CoreUtils"),
                .product(name: "Yams", package: "Yams")
            ]
        )
    ]
)
