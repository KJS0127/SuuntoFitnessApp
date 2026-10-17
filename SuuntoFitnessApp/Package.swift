// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SuuntoFitnessApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14) // 최신 macOS 14 빌드 호환성 명시
    ],
    products: [
        .library(
            name: "SuuntoFitnessApp",
            targets: ["SuuntoFitnessApp"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SuuntoFitnessApp",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "SuuntoFitnessAppTests",
            dependencies: ["SuuntoFitnessApp"],
            path: "Tests"
        )
    ]
)
