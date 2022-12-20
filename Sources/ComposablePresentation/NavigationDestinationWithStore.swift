
import ComposableArchitecture
import SwiftUI

extension View {
  /// Associates a destination view with a `Store` (with optional `State`) that can be used to push the view onto a `NavigationStack`.
  ///
  /// The sheet is presented if `State?` is non-`nil` and dismissed when it's `nil`.
  ///
  /// - Parameters:
  ///   - store: Store with an optional state.
  ///   - mapState: Maps the state. Defaults to a closure that returns unchanged state.
  ///   - onDismiss: Invoked when destination is dismissed.
  ///   - content: Creates content view with a store with unwrapped state.
  /// - Returns: View with navigation destination applied.
  @available(iOS 16.0, *)
  public func navigationDestination<State, Action, Content: View>(
    _ store: Store<State?, Action>,
    mapState: @escaping (State?) -> State? = { $0 },
    onDismiss: @escaping () -> Void,
    content: @escaping (Store<State, Action>) -> Content
  ) -> some View {
    background {
      WithViewStore(store.scope(state: { $0 != nil })) { viewStore in
        EmptyView().navigationDestination(
          isPresented: Binding(
            get: { viewStore.state },
            set: { isPresented in
              if isPresented == false {
                onDismiss()
              }
            }
          ),
          destination: {
            IfLetStore(
              store.scope(state: mapState),
              then: content
            )
          }
        )
      }
    }
  }
}
