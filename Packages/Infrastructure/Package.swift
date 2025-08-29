// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Infrastructure",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Infrastructure",
            targets: ["Infrastructure"]
        )
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../Application"),
        .package(path: "../TestSupport")
    ],
    targets: [
        .target(
            name: "Infrastructure",
            dependencies: [
                "Domain",
                "Application"
            ]
        ),
        .testTarget(
            name: "InfrastructureTests",
            dependencies: [
                "Infrastructure",
                .product(name: "Domain", package: "Domain"),
                .product(name: "Application", package: "Application"),
                .product(name: "TestSupport", package: "TestSupport")
            ]
        )
    ]
)