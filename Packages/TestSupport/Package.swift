// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TestSupport",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "TestSupport",
            targets: ["TestSupport"]
        )
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../Application"),
        .package(path: "../Infrastructure")
    ],
    targets: [
        .target(
            name: "TestSupport",
            dependencies: [
                "Domain",
                "Application",
                "Infrastructure"
            ]
        ),
        .testTarget(
            name: "TestSupportTests",
            dependencies: [
                "TestSupport",
                .product(name: "Domain", package: "Domain")
            ]
        )
    ]
)