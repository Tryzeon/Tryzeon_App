// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "chottu_link",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "chottu-link",
            targets: ["chottu_link"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "chottu_link",
            dependencies: [
                .target(name: "ChottuLinkSDK")
            ],
            path: "Classes"
        ),
        .binaryTarget(
            name: "ChottuLinkSDK",
            path: "Framework/ChottuLinkSDK.xcframework"
        )
    ]
)