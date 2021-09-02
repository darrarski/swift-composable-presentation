import ComposableArchitecture
import SwiftUI

extension View {
  /// Adds sheet using `Store` with an optional `State`
  ///
  /// The sheet is presented if `State?` is non-`nil` and dismissed when it's `nil`.
  ///
  /// - Parameters:
  ///   - store: Store with an optional state.
  ///   - state: Optional closure that takes `State?` and returns `State?` used to create destination view. Default value returns unchnaged state.
  ///   - onDismiss: Closure invoked when sheet is dismissed.
  ///   - destination: Closure that creates destination view with a store with non-optional state.
  /// - Returns: View with sheet added in a background view.
  public func sheet<State, Action, Content: View>(
    _ store: Store<State?, Action>,
    state: @escaping (State?) -> State? = { $0 },
    onDismiss: @escaping () -> Void,
    destination: @escaping (Store<State, Action>) -> Content
  ) -> some View {
    background(
      WithViewStore(store.scope(state: { $0 != nil })) { viewStore in
        EmptyView()
          .sheet(
            isPresented: Binding(
              get: { viewStore.state },
              set: { presented in
                if presented == false {
                  onDismiss()
                }
              }
            ),
            content: {
              IfLetStore(
                store.scope(state: state),
                then: destination
              )
            }
          )
      }
    )
  }
}
