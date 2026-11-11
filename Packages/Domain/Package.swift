// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "Domain",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "Domain", targets: ["Domain"])
    ],
    targets: [
        .target(name: "Domain"),
        .testTarget(name: "DomainTests", dependencies: ["Domain"])
    ]
)
