import ComposableArchitecture
import SwiftUI

/// `NavigationLink` wrapped with `WithViewStore`
public struct NavigationLinkSelectWithStore<State, Action, Tag, Destination, Label>: View
where Tag: Hashable,
      Destination: View,
      Label: View
{
  /// Create `NavigationLink` wrapped with `WithViewStore`.
  ///
  /// - The `Destination` is presented when `stateTag` for `State` is `tag`.
  ///
  /// - Parameters:
  ///   - store: Store with an optional state.
  ///   - mapState: Maps the state. Defaults to a closure that returns unchanged state.
  ///   - tag: The result value of `stateTag` that causes the link to present `Destination`.
  ///   - stateTag: A closure that returns `tag` for provided `State`.
  ///   - onSelect: A closure invoked when current `tag` selection changes.
  ///   - destination: Creates destination view with a store with unwrapped state.
  ///   - label: View used as a link's label.
  public init(
    _ store: Store<State?, Action>,
    mapState: @escaping (State?) -> State? = { $0 },
    tag: Tag,
    stateTag: @escaping (State) -> Tag,
    onSelect: @escaping (Tag?) -> Void,
    destination: @escaping (Store<State, Action>) -> Destination,
    label: @escaping () -> Label
  ) {
    self.store = store
    self.mapState = mapState
    self.tag = tag
    self.stateTag = stateTag
    self.onSelect = onSelect
    self.destination = destination
    self.label = label
  }

  let store: Store<State?, Action>
  let mapState: (State?) -> State?
  let tag: Tag
  let stateTag: (State) -> Tag
  let onSelect: (Tag?) -> Void
  let destination: (Store<State, Action>) -> Destination
  let label: () -> Label

  public var body: some View {
    WithViewStore(store.scope(state: { $0.map(stateTag) })) { viewStore in
      NavigationLink(
        tag: tag,
        selection: Binding(
          get: { viewStore.state },
          set: onSelect
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
