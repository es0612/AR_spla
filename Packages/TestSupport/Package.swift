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
        .package(path: "../Domain")
    ],
    targets: [
        .target(
            name: "TestSupport",
            dependencies: [
                "Domain"
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