import ComposableArchitecture
import SwiftUI

@main
struct ExamplesApp: SwiftUI.App {
  var body: some Scene {
    WindowGroup {
      MenuView(store: Store(
        initialState: Menu.State(
          // Uncomment to test deep-linking:
          // destination: .popToRoot(.init(
          //   first: .init(
          //     second: .init()
          //   )
          // ))
        ),
        reducer: Menu()._printChanges()
      ))
    }
  }
}
