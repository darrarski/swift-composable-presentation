import ComposableArchitecture
import SwiftUI

/// `NavigationLink` wrapped with `WithViewStore`.
@available(iOS, deprecated: 16, message: "use .navigationDestination(_:mapState:onDismiss:content:) view modifier (aka NavigationDestinationWithStore) inside a NavigationStack or NavigationSplitView")
@available(macOS, deprecated: 13, message: "use .navigationDestination(_:mapState:onDismiss:content:) view modifier (aka NavigationDestinationWithStore) inside a NavigationStack or NavigationSplitView")
public struct NavigationLinkWithStore<State, Action, Destination, Label>: View
where Destination: View,
      Label: View
{
  /// Create `NavigationLink` wrapped with `WithViewStore`.
  ///
  /// - The link is active if `State?` is non-`nil` and inactive when it's `nil`.
  ///
  /// - Parameters:
  ///   - store: Store with an optional state.
  ///   - mapState: Maps the state. Defaults to a closure that returns unchanged state.
  ///   - setActive: Invoked when link is activated and deactivated.
  ///   - destination: Creates destination view with a store with unwrapped state.
  ///   - label: View used as a link's label.
  public init(
    _ store: Store<State?, Action>,
    mapState: @escaping (State?) -> State? = { $0 },
    setActive: @escaping (Bool) -> Void,
    destination: @escaping (Store<State, Action>) -> Destination,
    label: @escaping () -> Label
  ) {
    self.store = store
    self.mapState = mapState
    self.setActive = setActive
    self.destination = destination
    self.label = label
  }

  let store: Store<State?, Action>
  let mapState: (State?) -> State?
  let setActive: (Bool) -> Void
  let destination: (Store<State, Action>) -> Destination
  let label: () -> Label

  public var body: some View {
    WithViewStore(store.scope(state: { $0 != nil })) { viewStore in
      _NavigationLink(
        isActive: Binding(
          get: { viewStore.state },
          set: setActive
        ),
        destination: {
          IfLetStore(
            store.scope(state: mapState),
            then: destination
          )
        },
        label: label
      )
    }
  }
}

@available(iOS, deprecated: 16, message: "use .navigationDestination(_:mapState:onDismiss:content:) view modifier (aka NavigationDestinationWithStore) inside a NavigationStack or NavigationSplitView")
@available(macOS, deprecated: 13, message: "use .navigationDestination(_:mapState:onDismiss:content:) view modifier (aka NavigationDestinationWithStore) inside a NavigationStack or NavigationSplitView")
extension NavigationLinkWithStore where Label == EmptyView {
  /// Create `NavigationLink` wrapped with `WithViewStore`.
  ///
  /// - The link is active if `State` is non-`nil` and inactive when it's `nil`.
  /// - Uses `EmptyView` as a link's label.
  ///
  /// - Parameters:
  ///   - store: Store with an optional state.
  ///   - mapState: Maps the state. Defaults to a closure that returns unchanged state.
  ///   - onDeactivate: Invoked when link is deactivated (dismissed).
  ///   - destination: Creates destination view with a store with unwrapped state.
  public init(
    _ store: Store<State?, Action>,
    mapState: @escaping (State?) -> State? = { $0 },
    onDeactivate: @escaping () -> Void,
    destination: @escaping (Store<State, Action>) -> Destination
  ) {
    self.init(
      store,
      mapState: mapState,
      setActive: { active in
        if active == false {
          onDeactivate()
        }
      },
      destination: destination,
      label: EmptyView.init
    )
  }
}
