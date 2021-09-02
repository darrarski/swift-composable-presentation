import ComposableArchitecture
import ComposablePresentation
import SwiftUI

@main
struct App: SwiftUI.App {
  var body: some Scene {
    WindowGroup {
      AppView(store: Store(
        initialState: AppState(),
        reducer: appReducer.debug(),
        environment: ()
      ))
    }
  }
}

struct AppState {}

enum AppAction {}

let appReducer = Reducer<AppState, AppAction, Void>.empty

struct AppView: View {
  let store: Store<AppState, AppAction>

  var body: some View {
    Text("Example")
  }
}

#if DEBUG
struct AppView_Previews: PreviewProvider {
  static var previews: some View {
    AppView(store: Store(
      initialState: AppState(),
      reducer: appReducer,
      environment: ()
    ))
  }
}
#endif
