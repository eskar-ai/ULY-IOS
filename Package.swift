// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UyghurLatinKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "UyghurLatinKit", targets: ["UyghurLatinKit"]),
    ],
    targets: [
        .target(
            name: "UyghurLatinKit",
            path: "Sources/UyghurLatinKit"
        ),
        .testTarget(
            name: "UyghurLatinKitTests",
            dependencies: ["UyghurLatinKit"],
            path: "Tests/UyghurLatinKitTests"
        ),
    ]
)
