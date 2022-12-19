// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutterrunner",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/eonist/FileWatcher.git", from: "0.2.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "flutterrunner",
            dependencies: [
                .product(name: "FileWatcher", package: "FileWatcher"),
            ]),
        .testTarget(
            name: "flutterrunnerTests",
            dependencies: ["flutterrunner"]),
    ]
)
