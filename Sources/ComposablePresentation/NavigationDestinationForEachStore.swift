import ComposableArchitecture
import SwiftUI

extension View {
  /// Associates a destination view with a presented data type for use within a navigation stack.
  ///
  /// - Parameters:
  ///   - store: Store with state of `IdentifiedArray<ID, State>` and `ParentAction`.
  ///   - action: Embeds `Action` for `ID` in a `ParentAction`.
  ///   - mapState: Maps the state. Defaults to a closure that returns unchanged state.
  ///   - destination: Creates destination view with a store of `State` and `Action`.
  /// - Returns: View with navigation destination applied.
  @available(iOS 16, macOS 13, *)
  public func navigationDestination<ID: Hashable, State, Action, ParentAction, Destination: View>(
    forEach store: Store<IdentifiedArray<ID, State>, ParentAction>,
    action: @escaping (ID, Action) -> ParentAction,
    mapState: @escaping (State?) -> State? = { $0 },
    destination: @escaping (Store<State, Action>) -> Destination
  ) -> some View {
    navigationDestination(for: ID.self) { id in
      IfLetStore(
        store.scope(
          state: { mapState($0[id: id]) },
          action: { action(id, $0) }
        ),
        then: destination
      )
    }
  }
}
