import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct Menu: ReducerProtocol {
  struct State {
    enum Destination {
      case sheet(SheetExample.State)
      case fullScreenCover(FullScreenCoverExample.State)
      case navigationDestination(NavigationDestinationExample.State)
      case forEachStore(ForEachStoreExample.State)
      case popToRoot(PopToRootExample.State)
      case switchStore(SwitchStoreExample.State)
      case destination(DestinationExample.State)
      case navigationStack(NavigationStackExample.State)
    }

    var destination: Menu.State.Destination?
  }

  enum Action {
    enum Destination {
      case sheet(SheetExample.Action)
      case fullScreenCover(FullScreenCoverExample.Action)
      case navigationDestination(NavigationDestinationExample.Action)
      case forEachStore(ForEachStoreExample.Action)
      case popToRoot(PopToRootExample.Action)
      case switchStore(SwitchStoreExample.Action)
      case destination(DestinationExample.Action)
      case navigationStack(NavigationStackExample.Action)
    }

    case present(Menu.State.Destination?)
    case destination(Menu.Action.Destination)
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
    self
      .presentingSheetExample()
      .presentingFullScreenCoverExample()
      .presentingNavigationDestinationExample()
      .presentingForEachStoreExample()
      .presentingPopToRootExample()
      .presentingSwitchStoreExample()
      .presentingDestinationExample()
      .presentingNavigationStackExample()
  }

  func presentingSheetExample() -> some ReducerProtocol<State, Action> {
    presenting(
      unwrapping: \.destination,
      case: /State.Destination.sheet,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.sheet),
      presented: SheetExample.init
    )
  }

  func presentingFullScreenCoverExample() -> some ReducerProtocol<State, Action> {
    presenting(
      unwrapping: \.destination,
      case: /State.Destination.fullScreenCover,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.fullScreenCover),
      presented: FullScreenCoverExample.init
    )
  }

  func presentingNavigationDestinationExample() -> some ReducerProtocol<State, Action> {
    presenting(
      unwrapping: \.destination,
      case: /State.Destination.navigationDestination,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.navigationDestination),
      presented: NavigationDestinationExample.init
    )
  }

  func presentingForEachStoreExample() -> some ReducerProtocol<State, Action> {
    presenting(
      unwrapping: \.destination,
      case: /State.Destination.forEachStore,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.forEachStore),
      presented: ForEachStoreExample.init
    )
  }

  func presentingPopToRootExample() -> some ReducerProtocol<State, Action> {
    presenting(
      unwrapping: \.destination,
      case: /State.Destination.popToRoot,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.popToRoot),
      presented: PopToRootExample.init
    )
  }

  func presentingSwitchStoreExample() -> some ReducerProtocol<State, Action> {
    presenting(
      unwrapping: \.destination,
      case: /State.Destination.switchStore,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.switchStore),
      presented: SwitchStoreExample.init
    )
  }

  func presentingDestinationExample() -> some ReducerProtocol<State, Action> {
    presenting(
      unwrapping: \.destination,
      case: /State.Destination.destination,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.destination),
      presented: DestinationExample.init
    )
  }

  func presentingNavigationStackExample() -> some ReducerProtocol<State, Action> {
    presenting(
      unwrapping: \.destination,
      case: /State.Destination.navigationStack,
      id: .notNil(),
      action: (/Action.destination).appending(path: /Action.Destination.navigationStack),
      presented: NavigationStackExample.init
    )
  }
}

struct MenuView: View {
  let store: StoreOf<Menu>

  var body: some View {
    IfLetStore(
      store.scope(state: \.destination),
      then: { store in
        VStack(spacing: 0) {
          SwitchStore(store) {
            CaseLet(
              state: (/Menu.State.Destination.sheet).extract(from:),
              action: { Menu.Action.destination(.sheet($0)) },
              then: SheetExampleView.init(store:)
            )
            CaseLet(
              state: (/Menu.State.Destination.fullScreenCover).extract(from:),
              action: { Menu.Action.destination(.fullScreenCover($0)) },
              then: FullScreenCoverExampleView.init(store:)
            )
            CaseLet(
              state: (/Menu.State.Destination.navigationDestination).extract(from:),
              action: { Menu.Action.destination(.navigationDestination($0)) },
              then: NavigationDestinationExampleView.init(store:)
            )
            CaseLet(
              state: (/Menu.State.Destination.forEachStore).extract(from:),
              action: { Menu.Action.destination(.forEachStore($0)) },
              then: ForEachStoreExampleView.init(store:)
            )
            CaseLet(
              state: (/Menu.State.Destination.popToRoot).extract(from:),
              action: { Menu.Action.destination(.popToRoot($0)) },
              then: PopToRootExampleView.init(store:)
            )
            CaseLet(
              state: (/Menu.State.Destination.switchStore).extract(from:),
              action: { Menu.Action.destination(.switchStore($0)) },
              then: SwitchStoreExampleView.init(store:)
            )
            CaseLet(
              state: (/Menu.State.Destination.destination).extract(from:),
              action: { Menu.Action.destination(.destination($0)) },
              then: DestinationExampleView.init(store:)
            )
            CaseLet(
              state: (/Menu.State.Destination.navigationStack).extract(from:),
              action: { Menu.Action.destination(.navigationStack($0)) },
              then: NavigationStackExampleView.init(store:)
            )
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)

          Divider()

          Button {
            ViewStore(store.stateless).send(.present(.none))
          } label: {
            Text("Quit example").padding()
          }
        }
      },
      else: {
        List {
          Section {
            Button {
              ViewStore(store.stateless).send(.present(.sheet(.init())))
            } label: {
              Text("SheetExample")
            }

            Button {
              ViewStore(store.stateless).send(.present(.fullScreenCover(.init())))
            } label: {
              Text("FullScreenCoverExample")
            }

            Button {
              ViewStore(store.stateless).send(.present(.navigationDestination(.init())))
            } label: {
              Text("NavigationDestinationExample")
            }

            Button {
              ViewStore(store.stateless).send(.present(.forEachStore(.init())))
            } label: {
              Text("ForEachStoreExample")
            }

            Button {
              ViewStore(store.stateless).send(.present(.popToRoot(.init())))
            } label: {
              Text("PopToRootExample")
            }

            Button {
              ViewStore(store.stateless).send(.present(.switchStore(.init())))
            } label: {
              Text("SwitchStoreExample")
            }

            Button {
              ViewStore(store.stateless).send(.present(.destination(.init())))
            } label: {
              Text("DestinationExample")
            }

            Button {
              ViewStore(store.stateless).send(.present(.navigationStack(.init())))
            } label: {
              Text("NavigationStackExample")
            }
          } header: {
            Text("Examples")
          }
        }
      }
    )
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
