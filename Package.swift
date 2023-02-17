// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mailosaur-swift",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "mailosaur-swift",
            targets: ["mailosaur-swift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Agitek-io/Perfect-SMTP.git", branch: "mailosaur-smtp-client")
    ],
    targets: [
        .target(
            name: "mailosaur-swift",
            dependencies: []),
        .testTarget(
            name: "mailosaur-swiftTests",
            dependencies: ["mailosaur-swift", .product(name: "PerfectSMTP", package: "Perfect-SMTP")],
        resources: [
            .process("Resources/cat.png"),
            .process("Resources/dog.png"),
            .process("Resources/testEmail.html"),
            .process("Resources/testEmail.txt")
        ]),
    ]
)
