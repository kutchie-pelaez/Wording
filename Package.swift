// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "Wording",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Wording",
            targets: [
                "Wording"
            ]
        ),
        .library(
            name: "WordingManager",
            targets: [
                "WordingManager"
            ]
        ),
        .library(
            name: "WordingManagerImpl",
            targets: [
                "WordingManagerImpl"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/kutchie-pelaez-packages/Core.git", branch: "master"),
        .package(url: "https://github.com/kutchie-pelaez-packages/Localization.git", branch: "master"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.6")
    ],
    targets: [
        .target(
            name: "Wording",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Language", package: "Localization"),
                .product(name: "Yams", package: "Yams")
            ]
        ),
        .target(
            name: "WordingManager",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Language", package: "Localization"),
                .product(name: "LocalizationManager", package: "Localization"),
                .target(name: "Wording")
            ]
        ),
        .target(
            name: "WordingManagerImpl",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Language", package: "Localization"),
                .product(name: "LocalizationManager", package: "Localization"),
                .target(name: "Wording"),
                .target(name: "WordingManager")
            ]
        )
    ]
)
