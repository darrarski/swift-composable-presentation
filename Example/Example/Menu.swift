//import ComposableArchitecture
//import ComposablePresentation
//import SwiftUI
//
//struct Menu: ReducerProtocol {
//  struct State {
//    enum Destination {
//      case sheet(SheetExample.State)
//      case fullScreenCover(FullScreenCoverExample.State)
//      case navigationLink(NavigationLinkExample.State)
//      case navigationLinkSelection(NavigationLinkSelectionExample.State)
//      case forEachStore(ForEachStoreExample.State)
//      case popToRoot(PopToRootExample.State)
//      case switchStore(SwitchStoreExample.State)
//      case destination(DestinationExample.State)
//
//      enum ID: Hashable {
//        case sheet
//        case fullScreenCover
//        case navigationLink
//        case navigationLinkSelection
//        case forEachStore
//        case popToRoot
//        case switchStore
//        case destination
//      }
//
//      var id: ID {
//        switch self {
//        case .sheet: return .sheet
//        case .fullScreenCover: return .fullScreenCover
//        case .navigationLink: return .navigationLink
//        case .navigationLinkSelection: return .navigationLinkSelection
//        case .forEachStore: return .forEachStore
//        case .popToRoot: return .popToRoot
//        case .switchStore: return .switchStore
//        case .destination: return .destination
//        }
//      }
//    }
//
//    var destination: Destination?
//  }
//
//  enum Action {
//    case present(Presentation?)
//    case sheet(SheetExample.Action)
//    case fullScreenCover(FullScreenCoverExample.Action)
//    case navigationLink(NavigationLinkExample.Action)
//    case navigationLinkSelection(NavigationLinkSelectionExample.Action)
//    case forEachStore(ForEachStoreExample.Action)
//    case popToRoot(PopToRootExample.Action)
//    case switchStore(SwitchStoreExample.Action)
//    case destination(DestinationExample.Action)
//  }
//
//  enum Presentation: Hashable {
//    case sheet
//    case fullScreenCover
//    case navigationLink
//    case navigationLinkSelection
//    case forEachStore
//    case popToRoot
//    case switchStore
//    case destination
//  }
//
//  var body: some ReducerProtocol<State, Action> {
//    Reduce { state, action in
//      switch action {
//      case .present(let presentation):
//        switch presentation {
//        case .sheet:
//          state.destination = .sheet(.init())
//        case .fullScreenCover:
//          state.destination = .fullScreenCover(.init())
//        case .navigationLink:
//          state.destination = .navigationLink(.init())
//        case .navigationLinkSelection:
//          state.destination = .navigationLinkSelection(.init())
//        case .forEachStore:
//          state.destination = .forEachStore(.init())
//        case .popToRoot:
//          state.destination = .popToRoot(.init())
//        case .switchStore:
//          state.destination = .switchStore(.init())
//        case .destination:
//          state.destination = .destination(.init())
//        case .none:
//          state.destination = nil
//        }
//        return .none
//
//      case .sheet,
//          .fullScreenCover,
//          .navigationLink,
//          .navigationLinkSelection,
//          .forEachStore,
//          .popToRoot,
//          .switchStore,
//          .destination:
//        return .none
//      }
//    }
//    // TODO: Fix long compile time when using multiple .presenting reducers
//    .presenting(
//      presentationID: Presentation.sheet,
//      unwrapping: \.destination,
//      case: /State.Destination.sheet,
//      id: .notNil(),
//      action: /Action.sheet,
//      presented: SheetExample.init
//    )
//    .presenting(
//      presentationID: Presentation.fullScreenCover,
//      unwrapping: \.destination,
//      case: /State.Destination.fullScreenCover,
//      id: .notNil(),
//      action: /Action.fullScreenCover,
//      presented: FullScreenCoverExample.init
//    )
//    .presenting(
//      presentationID: Presentation.navigationLink,
//      unwrapping: \.destination,
//      case: /State.Destination.navigationLink,
//      id: .notNil(),
//      action: /Action.navigationLink,
//      presented: NavigationLinkExample.init
//    )
//    .presenting(
//      presentationID: Presentation.navigationLinkSelection,
//      unwrapping: \.destination,
//      case: /State.Destination.navigationLinkSelection,
//      id: .notNil(),
//      action: /Action.navigationLinkSelection,
//      presented: NavigationLinkSelectionExample.init
//    )
//    .presenting(
//      presentationID: Presentation.forEachStore,
//      unwrapping: \.destination,
//      case: /State.Destination.forEachStore,
//      id: .notNil(),
//      action: /Action.forEachStore,
//      presented: ForEachStoreExample.init
//    )
//    .presenting(
//      presentationID: Presentation.popToRoot,
//      unwrapping: \.destination,
//      case: /State.Destination.popToRoot,
//      id: .notNil(),
//      action: /Action.popToRoot,
//      presented: PopToRootExample.init
//    )
//    .presenting(
//      presentationID: Presentation.switchStore,
//      unwrapping: \.destination,
//      case: /State.Destination.switchStore,
//      id: .notNil(),
//      action: /Action.switchStore,
//      presented: SwitchStoreExample.init
//    )
//    .presenting(
//      presentationID: Presentation.destination,
//      unwrapping: \.destination,
//      case: /State.Destination.destination,
//      id: .notNil(),
//      action: /Action.destination,
//      presented: DestinationExample.init
//    )
//    // Alternative composition (still slow):
//    //    .presenting(
//    //      presentationID: ObjectIdentifier(Menu.self),
//    //      state: .keyPath(\.destination),
//    //      id: .keyPath(\.?.id),
//    //      action: /Action.self,
//    //      presented: {
//    //        Scope(state: /State.Destination.sheet, action: /Action.sheet) {
//    //          SheetExample()
//    //        }
//    //        Scope(state: /State.Destination.fullScreenCover, action: /Action.fullScreenCover) {
//    //          FullScreenCoverExample()
//    //        }
//    //        Scope(state: /State.Destination.navigationLink, action: /Action.navigationLink) {
//    //          NavigationLinkExample()
//    //        }
//    //        Scope(state: /State.Destination.navigationLinkSelection, action: /Action.navigationLinkSelection) {
//    //          NavigationLinkSelectionExample()
//    //        }
//    //        Scope(state: /State.Destination.forEachStore, action: /Action.forEachStore) {
//    //          ForEachStoreExample()
//    //        }
//    //        Scope(state: /State.Destination.popToRoot, action: /Action.popToRoot) {
//    //          PopToRootExample()
//    //        }
//    //        Scope(state: /State.Destination.switchStore, action: /Action.switchStore) {
//    //          SwitchStoreExample()
//    //        }
//    //        Scope(state: /State.Destination.destination, action: /Action.destination) {
//    //          DestinationExample()
//    //        }
//    //      }
//    //    )
//  }
//}
//
//struct MenuView: View {
//  let store: StoreOf<Menu>
//
//  var body: some View {
//    WithViewStore(store.stateless) { viewStore in
//      IfLetStore(
//        store.scope(state: \.destination),
//        then: { store in
//          VStack(spacing: 0) {
//            ZStack {
//              IfLetStore(
//                store.scope(
//                  state: (/Menu.State.Destination.sheet).extract(from:),
//                  action: Menu.Action.sheet
//                ),
//                then: SheetExampleView.init(store:)
//              )
//
//              IfLetStore(
//                store.scope(
//                  state: (/Menu.State.Destination.fullScreenCover).extract(from:),
//                  action: Menu.Action.fullScreenCover
//                ),
//                then: FullScreenCoverExampleView.init(store:)
//              )
//
//              IfLetStore(
//                store.scope(
//                  state: (/Menu.State.Destination.navigationLink).extract(from:),
//                  action: Menu.Action.navigationLink
//                ),
//                then: NavigationLinkExampleView.init(store:)
//              )
//
//              IfLetStore(
//                store.scope(
//                  state: (/Menu.State.Destination.navigationLinkSelection).extract(from:),
//                  action: Menu.Action.navigationLinkSelection
//                ),
//                then: NavigationLinkSelectionExampleView.init(store:)
//              )
//
//              IfLetStore(
//                store.scope(
//                  state: (/Menu.State.Destination.forEachStore).extract(from:),
//                  action: Menu.Action.forEachStore
//                ),
//                then: ForEachStoreExampleView.init(store:)
//              )
//
//              IfLetStore(
//                store.scope(
//                  state: (/Menu.State.Destination.popToRoot).extract(from:),
//                  action: Menu.Action.popToRoot
//                ),
//                then: PopToRootExampleView.init(store:)
//              )
//
//              IfLetStore(
//                store.scope(
//                  state: (/Menu.State.Destination.switchStore).extract(from:),
//                  action: Menu.Action.switchStore
//                ),
//                then: SwitchStoreExampleView.init(store:)
//              )
//
//              IfLetStore(
//                store.scope(
//                  state: (/Menu.State.Destination.destination).extract(from:),
//                  action: Menu.Action.destination
//                ),
//                then: DestinationExampleView.init(store:)
//              )
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//
//            Divider()
//
//            Button {
//              viewStore.send(.present(.none))
//            } label: {
//              Text("Quit example").padding()
//            }
//          }
//        },
//        else: {
//          List {
//            Section {
//              Button {
//                viewStore.send(.present(.sheet))
//              } label: {
//                Text("SheetExample")
//              }
//
//              Button {
//                viewStore.send(.present(.fullScreenCover))
//              } label: {
//                Text("FullScreenCoverExample")
//              }
//
//              Button {
//                viewStore.send(.present(.navigationLink))
//              } label: {
//                Text("NavigationLinkExample")
//              }
//
//              Button {
//                viewStore.send(.present(.navigationLinkSelection))
//              } label: {
//                Text("NavigationLinkSelectionExample")
//              }
//
//              Button {
//                viewStore.send(.present(.forEachStore))
//              } label: {
//                Text("ForEachStoreExample")
//              }
//
//              Button {
//                viewStore.send(.present(.popToRoot))
//              } label: {
//                Text("PopToRootExample")
//              }
//
//              Button {
//                viewStore.send(.present(.switchStore))
//              } label: {
//                Text("SwitchStoreExample")
//              }
//
//              Button {
//                viewStore.send(.present(.destination))
//              } label: {
//                Text("DestinationExample")
//              }
//            } header: {
//              Text("Examples")
//            }
//          }
//        }
//      )
//    }
//  }
//}
//
//struct Menu_Previews: PreviewProvider {
//  static var previews: some View {
//    MenuView(store: Store(
//      initialState: Menu.State(),
//      reducer: Menu()
//    ))
//  }
//}
