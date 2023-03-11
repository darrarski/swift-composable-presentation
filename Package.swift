// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "swift-composable-presentation",
  platforms: [
    .iOS(.v14),
    .macOS(.v11),
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
      .upToNextMajor(from: "0.52.0")
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

//for target in package.targets {
//  target.swiftSettings = target.swiftSettings ?? []
//  target.swiftSettings?.append(
//    .unsafeFlags([
//      "-Xfrontend", "-warn-concurrency",
//      "-Xfrontend", "-strict-concurrency=complete",
//      "-Xfrontend", "-enable-actor-data-race-checks",
//      "-enable-library-evolution",
//      "-Xfrontend", "-debug-time-function-bodies",
//      "-Xfrontend", "-debug-time-expression-type-checking",
//    ])
//  )
//}
