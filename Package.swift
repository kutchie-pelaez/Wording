// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "Wording",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "Wording", targets: ["Wording"]),
        .library(name: "WordingManager", targets: ["WordingManager"]),
        .library(name: "WordingManagerImpl", targets: ["WordingManagerImpl"]),
        .plugin(name: "WordingGenerationPlugin",targets: ["WordingGenerationPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/kutchie-pelaez-packages/Core.git", branch: "master"),
        .package(url: "https://github.com/kutchie-pelaez-packages/Localization.git", branch: "master")
    ],
    targets: [
        .target(name: "Wording"),
        .target(name: "WordingManager", dependencies: [
            .product(name: "CoreUtils", package: "Core")
        ]),
        .target(name: "WordingManagerImpl", dependencies: [
            .product(name: "Core", package: "Core"),
            .product(name: "CoreUtils", package: "Core"),
            .product(name: "LocalizationManager", package: "Localization"),
            .product(name: "Logging", package: "swift-log"),
            .target(name: "Wording"),
            .target(name: "WordingManager")
        ]),
        .executableTarget(name: "WordingGenerationPluginTool", dependencies: [
            .product(name: "Yams", package: "Yams")
        ]),
        .plugin(name: "WordingGenerationPlugin", capability: .buildTool(), dependencies: [
            .target(name: "WordingGenerationPluginTool")
        ])
    ]
)
