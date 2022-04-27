// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pngquant",
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
            dependencies: [],
            sources: [
                "blur.c",
                "blur.h",
                "kmeans.c",
                "kmeans.h",
                "libimagequant.c",
                "libimagequant.h",
                "lodepng.c",
                "lodepng.h",
                "mediancut.c",
                "mediancut.h",
                "mempool.c",
                "mempool.h",
                "nearest.c",
                "nearest.h",
                "pam.c",
                "pam.h",
                "PNGQuantBinding.m"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
            ]
        ),
        .testTarget(
            name: "pnqquant.swiftTests",
            dependencies: ["pngquant"]),
    ]
)
