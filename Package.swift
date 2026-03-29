// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Macast",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(
            name: "Macast",
            targets: ["Macast"]
        ),
    ],
    dependencies: [],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "Macast",
            dependencies: [],
            path: "Sources",
            sources: ["Macast"],
            resources: [
                // 将资源文件添加到包中
                .process("Resources")
            ],
            linkerSettings: [
                // 链接系统框架
                .linkedFramework("AppKit"),
                .linkedFramework("Network"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("UserNotifications"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("Foundation")
            ]
        ),
        .testTarget(
            name: "MacastTests",
            dependencies: ["Macast"],
            path: "Tests"
        ),
    ]
)
