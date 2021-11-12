# Swift Composable Presentation

![Swift v5.4](https://img.shields.io/badge/swift-v5.4-orange.svg)
![platforms iOS macOS](https://img.shields.io/badge/platforms-iOS_macOS-blue.svg)

## 📝 Description

Navigation helpers for SwiftUI applications build with [ComposableArchitecture](https://github.com/pointfreeco/swift-composable-architecture/).

More info about the concept can be found in the article: [Thoughts on SwiftUI navigation](https://github.com/darrarski/darrarski/blob/main/2021/04/Thoughts-on-SwiftUI-navigation/README.md).

## 🏛 Project structure

```
ComposablePresentation (Xcode Workspace)
 ├─ swift-composable-presentation (Swift Package)
 |   └─ ComposablePresentation (Library)
 ├─ Example (Xcode Project)
 |   └─ Example (iOS Application)
 └─ Tests (Xcode Test Plan)
```

## ▶️ Usage

- Check out the included example app:
    - Open `ComposablePresentation.xcworkspace` in Xcode.
    - Example source code is contained in `Example` Xcode project.
    - Run the app using `Example` build scheme.
- Add as a dependency to your project:
    - Use [Swift Package Manager](https://swift.org/package-manager/).

## 🛠 Develop

- Use Xcode ≥ 12.5.
- Clone the repository or create a fork & clone it.
- Open `ComposablePresentation.xcworkspace` in Xcode
- Use `ComposablePresentation` scheme for building the library and running unit tests.
- If you want to contribute:
    - Create a pull request containing your changes or bugfixes.
    - Make sure to add tests for the new/updated code.

## ☕️ Do you like the project?

<a href="https://www.buymeacoffee.com/darrarski" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="60" width="217" style="height: 60px !important;width: 217px !important;" ></a>

## 📄 License

Copyright © 2021 Dariusz Rybicki Darrarski

License: [MIT](LICENSE)
