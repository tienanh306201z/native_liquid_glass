// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "native_liquid_glass",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "native_liquid_glass", targets: ["native_liquid_glass"])
    ],
    dependencies: [
        .package(url: "https://github.com/SVGKit/SVGKit", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "native_liquid_glass",
            dependencies: [
                .product(name: "SVGKit", package: "SVGKit"),
            ],
            path: "Sources/native_liquid_glass",
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
