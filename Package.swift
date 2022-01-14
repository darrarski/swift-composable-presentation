// swift-tools-version:5.4
import PackageDescription

let package = Package(
  name: "swift-composable-presentation",
  platforms: [
    .iOS(.v14),
    .macOS(.v10_15),
  ],
  products: [
    .library(
      name: "ComposablePresentation",
      targets: [
        "ComposablePresentation",
      ]
    ),
  ],
  dependencies: [
    .package(
      name: "swift-composable-architecture",
      url: "https://github.com/pointfreeco/swift-composable-architecture.git",
      .upToNextMajor(from: "0.33.1")
    ),
  ],
  targets: [
    .target(
      name: "ComposablePresentation",
      dependencies: [
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        ),
      ]
    ),
    .testTarget(
      name: "ComposablePresentationTests",
      dependencies: [
        .target(
          name: "ComposablePresentation"
        ),
      ]
    ),
  ]
)
