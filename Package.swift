// swift-tools-version:5.7
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
      url: "https://github.com/pointfreeco/swift-composable-architecture.git",
      .upToNextMajor(from: "0.47.2")
    ),
    .package(
      url: "https://github.com/pointfreeco/swiftui-navigation.git",
      .upToNextMajor(from: "0.4.5")
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
        .product(
          name: "SwiftUINavigation",
          package: "swiftui-navigation"
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
