import ComposableArchitecture
import SwiftUI

@main
struct ExamplesApp: SwiftUI.App {
  var body: some Scene {
    WindowGroup {
      MenuView(store: Store(
        initialState: Menu.State(),
        reducer: Menu()._printChanges()
      ))
    }
  }
}
