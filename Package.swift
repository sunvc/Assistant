// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Assistant",
    defaultLocalization: "en",
    platforms: [ .iOS(.v16)],
    
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Assistant",
            targets: ["Assistant"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sunvc/Defaults.git",.upToNextMajor(from: "0.0.1") ),
        .package(url: "https://github.com/MacPaw/OpenAI",.upToNextMajor(from: "0.4.4")),
        .package(url: "https://github.com/groue/GRDB.swift",.upToNextMajor(from: "7.5.0")),
        .package(url: "https://github.com/JohnSundell/Splash",.upToNextMajor(from: "0.16.0") ),
        .package(url: "https://github.com/onevcat/Kingfisher", .upToNextMajor(from: "8.3.3") ),
        .package(url: "https://github.com/swiftlang/swift-cmark", .upToNextMajor(from: "0.6.0") ),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", .upToNextMajor(from: "2.4.1") ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Assistant",
            dependencies: [
                .product(name: "Defaults", package: "Defaults"),
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Splash", package: "Splash"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ],
        ),
        
    ]
)
