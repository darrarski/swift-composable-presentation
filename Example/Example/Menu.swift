import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct Menu: ReducerProtocol {
  struct State {
    enum Destination {
      case sheet(SheetExample.State)
      case fullScreenCover(FullScreenCoverExample.State)
      case navigationLink(NavigationLinkExample.State)
      case navigationLinkSelection(NavigationLinkSelectionExample.State)
      case forEachStore(ForEachStoreExample.State)
      case popToRoot(PopToRootExample.State)
      case switchStore(SwitchStoreExample.State)
      case destination(DestinationExample.State)
    }

    var destination: Menu.State.Destination?
  }

  enum Action {
    enum Destination {
      case sheet(SheetExample.Action)
      case fullScreenCover(FullScreenCoverExample.Action)
      case navigationLink(NavigationLinkExample.Action)
      case navigationLinkSelection(NavigationLinkSelectionExample.Action)
      case forEachStore(ForEachStoreExample.Action)
      case popToRoot(PopToRootExample.Action)
      case switchStore(SwitchStoreExample.Action)
      case destination(DestinationExample.Action)
    }

    case present(Menu.State.Destination?)
    case destination(Menu.Action.Destination)
  }

  enum Presentation: Hashable {
    case sheet
    case fullScreenCover
    case navigationLink
    case navigationLinkSelection
    case forEachStore
    case popToRoot
    case switchStore
    case destination
  }

  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case .present(let destination):
        state.destination = destination
        return .none

      case .destination(_):
        return .none
      }
    }
    .presentingDestinations()
  }
}

extension ReducerProtocolOf<Menu> {
  func presentingDestinations() -> some ReducerProtocol<State, Action> {
    presenting(
      presentationID: Menu.Presentation.sheet,
      unwrapping: \.destination,
      case: /State.Destination.sheet,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.sheet),
      presented: SheetExample.init
    )
    .presenting(
      presentationID: Menu.Presentation.fullScreenCover,
      unwrapping: \.destination,
      case: /State.Destination.fullScreenCover,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.fullScreenCover),
      presented: FullScreenCoverExample.init
    )
    .presenting(
      presentationID: Menu.Presentation.navigationLink,
      unwrapping: \.destination,
      case: /State.Destination.navigationLink,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.navigationLink),
      presented: NavigationLinkExample.init
    )
    .presenting(
      presentationID: Menu.Presentation.navigationLinkSelection,
      unwrapping: \.destination,
      case: /State.Destination.navigationLinkSelection,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.navigationLinkSelection),
      presented: NavigationLinkSelectionExample.init
    )
    .presenting(
      presentationID: Menu.Presentation.forEachStore,
      unwrapping: \.destination,
      case: /State.Destination.forEachStore,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.forEachStore),
      presented: ForEachStoreExample.init
    )
    .presenting(
      presentationID: Menu.Presentation.popToRoot,
      unwrapping: \.destination,
      case: /State.Destination.popToRoot,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.popToRoot),
      presented: PopToRootExample.init
    )
    .presenting(
      presentationID: Menu.Presentation.switchStore,
      unwrapping: \.destination,
      case: /State.Destination.switchStore,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.switchStore),
      presented: SwitchStoreExample.init
    )
    .presenting(
      presentationID: Menu.Presentation.destination,
      unwrapping: \.destination,
      case: /State.Destination.destination,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.destination),
      presented: DestinationExample.init
    )
  }
}

struct MenuView: View {
  let store: StoreOf<Menu>

  var body: some View {
    WithViewStore(store.stateless) { viewStore in
      IfLetStore(
        store.scope(state: \.destination),
        then: { store in
          VStack(spacing: 0) {
            ZStack {
              IfLetStore(
                store.scope(
                  state: (/Menu.State.Destination.sheet).extract(from:),
                  action: { Menu.Action.destination(.sheet($0)) }
                ),
                then: SheetExampleView.init(store:)
              )

              IfLetStore(
                store.scope(
                  state: (/Menu.State.Destination.fullScreenCover).extract(from:),
                  action: { Menu.Action.destination(.fullScreenCover($0)) }
                ),
                then: FullScreenCoverExampleView.init(store:)
              )

              IfLetStore(
                store.scope(
                  state: (/Menu.State.Destination.navigationLink).extract(from:),
                  action: { Menu.Action.destination(.navigationLink($0)) }
                ),
                then: NavigationLinkExampleView.init(store:)
              )

              IfLetStore(
                store.scope(
                  state: (/Menu.State.Destination.navigationLinkSelection).extract(from:),
                  action: { Menu.Action.destination(.navigationLinkSelection($0)) }
                ),
                then: NavigationLinkSelectionExampleView.init(store:)
              )

              IfLetStore(
                store.scope(
                  state: (/Menu.State.Destination.forEachStore).extract(from:),
                  action: { Menu.Action.destination(.forEachStore($0)) }
                ),
                then: ForEachStoreExampleView.init(store:)
              )

              IfLetStore(
                store.scope(
                  state: (/Menu.State.Destination.popToRoot).extract(from:),
                  action: { Menu.Action.destination(.popToRoot($0)) }
                ),
                then: PopToRootExampleView.init(store:)
              )

              IfLetStore(
                store.scope(
                  state: (/Menu.State.Destination.switchStore).extract(from:),
                  action: { Menu.Action.destination(.switchStore($0)) }
                ),
                then: SwitchStoreExampleView.init(store:)
              )

              IfLetStore(
                store.scope(
                  state: (/Menu.State.Destination.destination).extract(from:),
                  action: { Menu.Action.destination(.destination($0)) }
                ),
                then: DestinationExampleView.init(store:)
              )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            Button {
              viewStore.send(.present(.none))
            } label: {
              Text("Quit example").padding()
            }
          }
        },
        else: {
          List {
            Section {
              Button {
                viewStore.send(.present(.sheet(.init())))
              } label: {
                Text("SheetExample")
              }

              Button {
                viewStore.send(.present(.fullScreenCover(.init())))
              } label: {
                Text("FullScreenCoverExample")
              }

              Button {
                viewStore.send(.present(.navigationLink(.init())))
              } label: {
                Text("NavigationLinkExample")
              }

              Button {
                viewStore.send(.present(.navigationLinkSelection(.init())))
              } label: {
                Text("NavigationLinkSelectionExample")
              }

              Button {
                viewStore.send(.present(.forEachStore(.init())))
              } label: {
                Text("ForEachStoreExample")
              }

              Button {
                viewStore.send(.present(.popToRoot(.init())))
              } label: {
                Text("PopToRootExample")
              }

              Button {
                viewStore.send(.present(.switchStore(.init())))
              } label: {
                Text("SwitchStoreExample")
              }

              Button {
                viewStore.send(.present(.destination(.init())))
              } label: {
                Text("DestinationExample")
              }
            } header: {
              Text("Examples")
            }
          }
        }
      )
    }
  }
}

struct Menu_Previews: PreviewProvider {
  static var previews: some View {
    MenuView(store: Store(
      initialState: Menu.State(),
      reducer: Menu()
    ))
  }
}
