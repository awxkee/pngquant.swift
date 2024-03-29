// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pngquant",
    platforms: [
        .iOS(.v12), .macCatalyst(.v14), .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "pngquant",
            targets: ["pngquant"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "pngquant",
            dependencies: [.target(name: "pngquantc")]),
        .target(
            name: "pngquantc",
            dependencies: ["libimagequant", "libspng"],
            sources: [
                "PNGImage.mm",
                "PNGEncoder.cpp",
                "Quantinizer.cpp",
                "PNGSafeBuffer.cpp",
                "PNGUnsafeBuffer.cpp"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .define("NDEBUG"),
            ],
            linkerSettings: [.linkedFramework("Accelerate")]
        ),
        .binaryTarget(name: "libimagequant", path: "Sources/libimagequant.xcframework"),
        .binaryTarget(name: "libspng", path: "Sources/libspng.xcframework"),
        .testTarget(
            name: "pnqquant.swiftTests",
            dependencies: ["pngquant"]),
    ]
)
