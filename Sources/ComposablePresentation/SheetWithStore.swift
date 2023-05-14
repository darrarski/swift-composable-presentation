import ComposableArchitecture
import SwiftUI

extension View {
  /// Adds sheet using `Store` with an optional `State`
  ///
  /// The sheet is presented if `State?` is non-`nil` and dismissed when it's `nil`.
  ///
  /// - Parameters:
  ///   - store: Store with an optional state.
  ///   - mapState: Maps the state. Defaults to a closure that returns unchanged state.
  ///   - onDismiss: Invoked when sheet is dismissed.
  ///   - content: Creates content view with a store with unwrapped state.
  /// - Returns: View with sheet added in a background view.
  @MainActor
  public func sheet<State, Action, Content: View>(
    _ store: Store<State?, Action>,
    mapState: @escaping (State?) -> State? = { $0 },
    onDismiss: @escaping () -> Void,
    content: @escaping (Store<State, Action>) -> Content
  ) -> some View {
    background(
      WithViewStore(store, observe: { $0 != nil }) { viewStore in
        EmptyView()
          .sheet(
            isPresented: Binding(
              get: { viewStore.state },
              set: { isPresented in
                if isPresented == false {
                  onDismiss()
                }
              }
            ),
            content: {
              IfLetStore(
                store.scope(state: mapState, action: { $0 }),
                then: content
              )
            }
          )
      }
    )
  }
}
