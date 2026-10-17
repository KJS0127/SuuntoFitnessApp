// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SuuntoFitnessApp",
    platforms: [
        .iOS(.v17) // 순수 iOS 17+ 전용 앱
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
