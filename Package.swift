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
        ),
        .plugin(
            name: "WordingGenerationPlugin",
            targets: [
                "WordingGenerationPlugin"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.6"),
        .package(url: "https://github.com/kutchie-pelaez-packages/Core.git", branch: "master"),
        .package(url: "https://github.com/kutchie-pelaez-packages/Localization.git", branch: "master")
    ],
    targets: [
        .target(name: "Wording"),
        .target(
            name: "WordingManager",
            dependencies: [
                .product(name: "Core", package: "Core")
            ]
        ),
        .target(
            name: "WordingManagerImpl",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Localization", package: "Localization"),
                .product(name: "LocalizationManager", package: "Localization"),
                .target(name: "Wording"),
                .target(name: "WordingManager")
            ]
        ),
        .executableTarget(
            name: "WordingGenerationPluginTool",
            dependencies: [
                .product(name: "Yams", package: "Yams")
            ]
        ),
        .plugin(
            name: "WordingGenerationPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "WordingGenerationPluginTool")
            ]
        )
    ]
)
