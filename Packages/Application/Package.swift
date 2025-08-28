// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Application",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Application",
            targets: ["Application"]
        )
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../TestSupport")
    ],
    targets: [
        .target(
            name: "Application",
            dependencies: ["Domain"]
        ),
        .testTarget(
            name: "ApplicationTests",
            dependencies: [
                "Application",
                .product(name: "Domain", package: "Domain"),
                .product(name: "TestSupport", package: "TestSupport")
            ]
        )
    ]
)