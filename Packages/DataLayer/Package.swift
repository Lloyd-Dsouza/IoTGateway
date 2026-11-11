// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "DataLayer",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "DataLayer", targets: ["DataLayer"])
    ],
    dependencies: [
        .package(path: "../Domain")
    ],
    targets: [
        .target(
            name: "DataLayer",
            dependencies: [.product(name: "Domain", package: "Domain")]
        ),
        .testTarget(
            name: "DataLayerTests",
            dependencies: [
                "DataLayer",
                .product(name: "Domain", package: "Domain")
            ]
        )
    ]
)
