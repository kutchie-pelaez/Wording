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
        .package(name: "Yams", url: "https://github.com/jpsim/Yams.git", from: "4.0.6")
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
            name: "Wording",
            dependencies: [
                .product(name: "CoreUtils", package: "CoreUtils"),
                .product(name: "Yams", package: "Yams")
            ]
        )
    ]
)
