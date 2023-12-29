// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KodiConnector",
    platforms: [.macOS(.v12), .iOS(.v14), .watchOS(.v10)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(name: "KodiConnector", targets: ["KodiConnector"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/katoemba/connectorprotocol.git", .upToNextMajor(from: "1.9.0")),
        .package(url: "https://github.com/katoemba/rxnetservice.git", .upToNextMajor(from: "0.2.3")),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.0.0")),
        .package(url: "https://github.com/RxSwiftCommunity/RxSwiftExt.git", .upToNextMajor(from: "6.0.0")),
        .package(url: "https://github.com/daltoniam/Starscream.git", .upToNextMajor(from: "3.1.1"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "KodiConnector",
            dependencies: [.product(name: "ConnectorProtocol", package: "connectorprotocol"),
                           .product(name: "RxNetService", package: "rxnetservice"),
                           .product(name: "RxRelay", package: "rxswift"),
                           .product(name: "RxSwift", package: "rxswift"),
                           .product(name: "RxSwiftExt", package: "rxswiftext"),
                           .product(name: "Starscream", package: "starscream")]),
        .testTarget(
            name: "KodiConnectorTests",
            dependencies: ["KodiConnector"])
    ]
)
