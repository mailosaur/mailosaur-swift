// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Mailosaur",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "Mailosaur",
            targets: ["Mailosaur"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mailosaur/Perfect-SMTP.git", branch: "mailosaur-smtp-client")
    ],
    targets: [
        .target(
            name: "Mailosaur",
            dependencies: []),
        .testTarget(
            name: "MailosaurTests",
            dependencies: ["Mailosaur", .product(name: "PerfectSMTP", package: "Perfect-SMTP")],
        resources: [
            .process("Resources/cat.png"),
            .process("Resources/dog.png"),
            .process("Resources/testEmail.html"),
            .process("Resources/testEmail.txt")
        ]),
    ]
)
