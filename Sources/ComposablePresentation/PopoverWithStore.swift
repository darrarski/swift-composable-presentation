import ComposableArchitecture
import SwiftUI

extension View {
  /// Adds popover using `Store` with an optional `State`
  ///
  /// The popover is presented if `State?` is non-`nil` and dismissed when it's `nil`.
  ///
  /// - Parameters:
  ///   - store: Store with an optional state.
  ///   - mapState: Maps the state. Defaults to a closure that returns unchanged state.
  ///   - onDismiss: Invoked when popover is dismissed.
  ///   - attachmentAnchor: The positioning anchor that defines the attachment point of the popover in macOS.
  ///       The default is `.rect(.bounds)`. iOS ignores this parameter.
  ///   - arrowEdge: The edge of the `attachmentAnchor` that defines the location of the popover's arrow.
  ///       The default is `.top`.
  ///   - content: Creates content view with a store with unwrapped state.
  /// - Returns: View with popover added in a background view.
  public func popover<State, Action, Content: View>(
    _ store: Store<State?, Action>,
    mapState: @escaping (State?) -> State? = { $0 },
    onDismiss: @escaping () -> Void,
    attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
    arrowEdge: Edge = .top,
    content: @escaping (Store<State, Action>) -> Content
  ) -> some View {
    background(
      WithViewStore(store, observe: { $0 != nil }) { viewStore in
        EmptyView()
          .popover(
            isPresented: Binding(
              get: { viewStore.state },
              set: { isPresented in
                if isPresented == false {
                  onDismiss()
                }
              }
            ),
            attachmentAnchor: attachmentAnchor,
            arrowEdge: arrowEdge,
            content: {
              IfLetStore(
                store.scope(state: mapState),
                then: content
              )
            }
          )
      }
    )
  }
}
