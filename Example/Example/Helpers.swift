import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct _NavigationStack<Content: View>: View {
  let content: () -> Content

  var body: some View {
    if #available(iOS 16.0, *) {
      NavigationStack(root: content)
    } else {
      NavigationView(content: content)
    }
  }
}

extension View {
  @MainActor
  func _navigationDestination<State, Action, Destination: View>(
    _ store: Store<State?, Action>,
    mapState: @escaping (State?) -> State? = { $0 },
    onDismiss: @escaping () -> Void,
    destination: @escaping (Store<State, Action>) -> Destination
  ) -> some View {
    if #available(iOS 16.0, *) {
      return navigationDestination(
        store,
        mapState: mapState,
        onDismiss: onDismiss,
        content: destination
      )
    } else {
      return background(
        NavigationLinkWithStore(
          store,
          onDeactivate: onDismiss,
          destination: destination
        )
      )
    }
  }
}
