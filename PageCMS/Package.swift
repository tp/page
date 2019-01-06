// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PageCMS",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/kylef/Stencil.git", .upToNextMinor(from: "0.8.0")),
        .package(url: "https://github.com/vapor-community/markdown.git", .upToNextMinor(from: "0.4.0")),
        .package(url: "https://github.com/nvzqz/FileKit", .upToNextMajor(from: "5.0.0"))
        
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "PageCMS",
            dependencies: [
                "PageCMSLib",
                "SwiftMarkdown",
                "Stencil",
                "FileKit"
            ]),
        .target(
            name: "PageCMSLib",
            dependencies: [
                "SwiftMarkdown",
                "Stencil",
                "FileKit"
            ]),
        .testTarget(
            name: "PageCMSLibTests",
            dependencies: ["PageCMSLib"]
        )
    ]
)