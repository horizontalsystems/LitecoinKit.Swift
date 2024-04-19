// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "LitecoinKit",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "LitecoinKit",
            targets: ["LitecoinKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/horizontalsystems/BitcoinCore.Swift.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/greymass/swift-scrypt.git", from: "1.0.0"),
        .package(url: "https://github.com/horizontalsystems/HsToolKit.Swift.git", .upToNextMajor(from: "2.0.5")),
    ],
    targets: [
        .target(
            name: "LitecoinKit",
            dependencies: [
                .product(name: "Scrypt", package: "swift-scrypt"),
                .product(name: "BitcoinCore", package: "BitcoinCore.Swift"),
                .product(name: "HsToolKit", package: "HsToolKit.Swift"),
            ]
        ),
    ]
)
