import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct Menu: ReducerProtocol {
  enum Destination: Hashable {
    case sheet
    case fullScreenCover
    case navigationLink
    case navigationLinkSelection
    case forEachStore
    case popToRoot
    case switchStore
    case destination
  }

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

      var destination: Menu.Destination {
        switch self {
        case .sheet: return .sheet
        case .fullScreenCover: return .fullScreenCover
        case .navigationLink: return .navigationLink
        case .navigationLinkSelection: return .navigationLinkSelection
        case .forEachStore: return .forEachStore
        case .popToRoot: return .popToRoot
        case .switchStore: return .switchStore
        case .destination: return .destination
        }
      }
    }

    var destination: Destination?
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

    case present(Menu.Destination?)
    case destination(Destination)
  }

  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case .present(let destination):
        switch destination {
        case .sheet: state.destination = .sheet(.init())
        case .fullScreenCover: state.destination = .fullScreenCover(.init())
        case .navigationLink: state.destination = .navigationLink(.init())
        case .navigationLinkSelection: state.destination = .navigationLinkSelection(.init())
        case .forEachStore: state.destination = .forEachStore(.init())
        case .popToRoot: state.destination = .popToRoot(.init())
        case .switchStore: state.destination = .switchStore(.init())
        case .destination: state.destination = .destination(.init())
        case .none: state.destination = nil
        }
        return .none

      case .destination(_):
        return .none
      }
    }
    // TODO: Fix long compile time when using multiple .presenting reducers
    // Alternative composition (still slow):
    //    .presenting(
    //      presentationID: ObjectIdentifier(Menu.self),
    //      state: .keyPath(\.destination),
    //      id: .keyPath(\.?.id),
    //      action: /Action.self,
    //      presented: {
    //        Scope(state: /State.Destination.sheet, action: /Action.sheet) {
    //          SheetExample()
    //        }
    //        Scope(state: /State.Destination.fullScreenCover, action: /Action.fullScreenCover) {
    //          FullScreenCoverExample()
    //        }
    //        Scope(state: /State.Destination.navigationLink, action: /Action.navigationLink) {
    //          NavigationLinkExample()
    //        }
    //        Scope(state: /State.Destination.navigationLinkSelection, action: /Action.navigationLinkSelection) {
    //          NavigationLinkSelectionExample()
    //        }
    //        Scope(state: /State.Destination.forEachStore, action: /Action.forEachStore) {
    //          ForEachStoreExample()
    //        }
    //        Scope(state: /State.Destination.popToRoot, action: /Action.popToRoot) {
    //          PopToRootExample()
    //        }
    //        Scope(state: /State.Destination.switchStore, action: /Action.switchStore) {
    //          SwitchStoreExample()
    //        }
    //        Scope(state: /State.Destination.destination, action: /Action.destination) {
    //          DestinationExample()
    //        }
    //      }
    //    )
    .presenting(
      presentationID: Destination.sheet,
      unwrapping: \.destination,
      case: /State.Destination.sheet,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.sheet),
      presented: SheetExample.init
    )
    .presenting(
      presentationID: Destination.fullScreenCover,
      unwrapping: \.destination,
      case: /State.Destination.fullScreenCover,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.fullScreenCover),
      presented: FullScreenCoverExample.init
    )
    .presenting(
      presentationID: Destination.navigationLink,
      unwrapping: \.destination,
      case: /State.Destination.navigationLink,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.navigationLink),
      presented: NavigationLinkExample.init
    )
    .presenting(
      presentationID: Destination.navigationLinkSelection,
      unwrapping: \.destination,
      case: /State.Destination.navigationLinkSelection,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.navigationLinkSelection),
      presented: NavigationLinkSelectionExample.init
    )
    .presenting(
      presentationID: Destination.forEachStore,
      unwrapping: \.destination,
      case: /State.Destination.forEachStore,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.forEachStore),
      presented: ForEachStoreExample.init
    )
    .presenting(
      presentationID: Destination.popToRoot,
      unwrapping: \.destination,
      case: /State.Destination.popToRoot,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.popToRoot),
      presented: PopToRootExample.init
    )
    .presenting(
      presentationID: Destination.switchStore,
      unwrapping: \.destination,
      case: /State.Destination.switchStore,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.switchStore),
      presented: SwitchStoreExample.init
    )
    .presenting(
      presentationID: Destination.destination,
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
                viewStore.send(.present(.sheet))
              } label: {
                Text("SheetExample")
              }

              Button {
                viewStore.send(.present(.fullScreenCover))
              } label: {
                Text("FullScreenCoverExample")
              }

              Button {
                viewStore.send(.present(.navigationLink))
              } label: {
                Text("NavigationLinkExample")
              }

              Button {
                viewStore.send(.present(.navigationLinkSelection))
              } label: {
                Text("NavigationLinkSelectionExample")
              }

              Button {
                viewStore.send(.present(.forEachStore))
              } label: {
                Text("ForEachStoreExample")
              }

              Button {
                viewStore.send(.present(.popToRoot))
              } label: {
                Text("PopToRootExample")
              }

              Button {
                viewStore.send(.present(.switchStore))
              } label: {
                Text("SwitchStoreExample")
              }

              Button {
                viewStore.send(.present(.destination))
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
