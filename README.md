# Swift Composable Presentation

![Swift v5.7](https://img.shields.io/badge/swift-v5.7-orange.svg)
![platforms iOS, macOS](https://img.shields.io/badge/platforms-iOS,_macOS-blue.svg)

Presentation and navigation helpers for SwiftUI applications build with [ComposableArchitecture](https://github.com/pointfreeco/swift-composable-architecture/).

## 📝 Description

If you are familiar with [ComposableArchitecture](https://github.com/pointfreeco/swift-composable-architecture/), you know how to build a fully-featured application from isolated components. You can combine reducers and scope stores to achieve that. However, when one component optionally embeds another one (or presents in navigation meaning), it could be tricky to handle side effects correctly.

The `ComposablePresentation` is a library that helps to compose reducers in apps built with [ComposableArchitecture](https://github.com/pointfreeco/swift-composable-architecture/). You can use it whenever you need to conditionally present a component, like when presenting a sheet, navigating between screens, or displaying a list of components. It also comes with SwiftUI helpers for sheets, navigation links, for-each-store, and other presentations.

`Reducer.presenting` functions allows combining the reducer with a reducer of an optionally presented component. Once the component is dismissed (its optional state changes from honest value to `nil`), the effects returned by its reducer are automatically canceled.

More info about the concept can be found in the article: [Thoughts on SwiftUI navigation](https://github.com/darrarski/darrarski/blob/main/2021/04/Thoughts-on-SwiftUI-navigation/README.md).

## 🏛 Project structure

```
ComposablePresentation (Xcode Workspace)
 ├─ swift-composable-presentation (Swift Package)
 |   └─ ComposablePresentation (Library)
 └─ Example (Xcode Project)
     └─ Example (iOS Application)
```

## 📖 Usage

Use [Swift Package Manager](https://swift.org/package-manager/) to add `ComposablePresentation` as a dependency to your project.

This repository contains an example iOS application built with SwiftUI and [ComposableArchitecture](https://github.com/pointfreeco/swift-composable-architecture/).

- Open `ComposablePresentation.xcworkspace` in Xcode.
- Example source code is contained in the `Example` Xcode project.
- Run the app using the `Example` build scheme.

### ➡️ [Sheet example](Example/Example/SheetExample.swift)

SwiftUI example that shows how to present a sheet with content driven by a store with an optional state. The sheet is presented when the store's state has an honest value and dismisses when it becomes `nil`. All effects produced by the store's reducer while the content is presented are canceled when the sheet is dismissed.

### ➡️ [Full screen cover example](Example/Example/FullScreenCoverExample.swift)

SwiftUI example that shows how to present a full-screen cover with content driven by a store with an optional state. The cover is presented when the store's state has an honest value and dismisses when it becomes `nil`. All effects produced by the store's reducer while the content is presented are canceled when the cover dismisses.

### ➡️ [NavigationLink example](Example/Example/NavigationLinkExample.swift)

SwiftUI example with `NavigationLink` driven by a store with an optional state. The link is active when the store's state has an honest value, and inactive when it becomes `nil`. All effects produced by the store's reducer while the content is presented are canceled when the link destination dismisses.

### ➡️ [ForEachStore example](Example/Example/ForEachStoreExample.swift)

SwiftUI example with a list of components. When a component is deleted from the list, all effects produced by its reducer are canceled.

### ➡️ [Pop-to-root example](Example/Example/PopToRootExample.swift)

SwiftUI example that shows how to dismiss multiple navigation links at once (poping back to root view) in state-driven navigation. All effects produced by reducers of presented stores are canceled on dismiss.

### ➡️ [Replay non-nil state](Example/Example/PopToRootExample.swift#L69)

In most cases, the presentation has a corresponding present and dismiss animations. When we drive it with an optional state, it becomes a problem. Let's say we want to programmatically dismiss a sheet, so we set its state to `nil`. It triggers the dismiss animation, but due to the fact that our state is already `nil`, we can't present the sheet content during this transition. As a workaround, `ComposablePresentation` provides `replayNonNil` function that can be passed to the optional `mapState` parameter of `NavigationLinkWithStore`, `View.sheet`, `View. popover`, and other SwiftUI helper functions.

### ➡️ [SwitchStore example](Example/Example/SwitchStoreExample.swift)

SwiftUI example of a component that conditionally presents one of two child components. The state is modeled as an enum with two cases. All effects produced by the child component are canceled when the child component is removed from the parent component.

### ➡️ [Destination example](Example/Example/DestinationExample.swift)

SwiftUI example of a component that presents a mutually-exclusive destination. The destination is represented by an optional enum case. Each case is presented using a different navigation pattern (navigation link, sheet, alert, etc.). All effects produced by the presented component are canceled when the destination is dismissed or changed. This design of modeling navigation is inspired by ["Modern SwiftUI" video series](https://www.pointfree.co/collections/swiftui/modern-swiftui) by [Point-Free](https://www.pointfree.co/).

### ▶️ [Deeplink example](Example/Example/App.swift)

Navigation composed with this library is driven by a declarative state. This makes it easy to handle deep links and navigate to any screen of the app. Several workarounds were applied to fix SwiftUI navigation issues (this was only possible thanks to [swiftui-navigation](https://github.com/pointfreeco/swiftui-navigation) library by [Point-Free](https://www.pointfree.co/)). Change the initial state in [Example/App.swift](Example/Example/App.swift) to navigate to any screen when the app starts.

## 🛠 Develop

- Use Xcode (version ≥ 14).
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
