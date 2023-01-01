import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct NavigationLinkSelectionExample: ReducerProtocol {
  struct Item: Identifiable, Equatable {
    var id: String
  }

  struct State {
    var items: [Item] = [
      Item(id: "A"),
      Item(id: "B"),
      Item(id: "C"),
    ]
    var detail: Detail.State? = nil
  }

  enum Action {
    case didSelect(itemId: Item.ID?)
    case detail(Detail.Action)
  }

  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case .didSelect(.some(let itemId)):
        state.detail = state.items
          .first { $0.id == itemId }
          .map(Detail.State.init(item:))
        return .none

      case .didSelect(.none), .detail(.didTapDismissButton):
        state.detail = nil
        return .none

      case .detail(_):
        return .none
      }
    }
    .presenting(
      presentationID: ObjectIdentifier(NavigationLinkSelectionExample.self),
      state: .keyPath(\.detail),
      id: .keyPath(\.?.item.id),
      action: /Action.detail,
      presented: Detail.init
    )
  }

  // MARK: - Child Reducers

  struct Detail: ReducerProtocol {
    struct State {
      init(item: Item) {
        self.item = item
      }

      var item: Item
      var timer = TimerExample.State()
    }

    enum Action {
      case didTapDismissButton
      case timer(TimerExample.Action)
    }

    var body: some ReducerProtocol<State, Action> {
      Scope(state: \.timer, action: /Action.timer) {
        TimerExample()
      }
    }
  }
}

struct NavigationLinkSelectionExampleView: View {
  let store: StoreOf<NavigationLinkSelectionExample>

  struct ViewState: Equatable {
    let items: [NavigationLinkSelectionExample.Item]
    let selectedItemID: NavigationLinkSelectionExample.Item.ID?

    init(state: NavigationLinkSelectionExample.State) {
      items = state.items
      selectedItemID = state.detail?.item.id
    }
  }

  var body: some View {
    WithViewStore(store.scope(state: ViewState.init)) { viewStore in
      _NavigationStack {
        List {
          ForEach(viewStore.items) { item in
            NavigationLink(
              tag: item.id,
              selection: viewStore.binding(
                get: \.selectedItemID,
                send: NavigationLinkSelectionExample.Action.didSelect
              ),
              destination: {
                IfLetStore(
                  store.scope(
                    state: \.detail,
                    action: NavigationLinkSelectionExample.Action.detail
                  ),
                  then: DetailView.init(store:)
                )
              },
              label: { Text("Item \(item.id)") }
            )
          }
        }
        .navigationTitle("NavigationLinkSelectionExample")
      }
    }
  }

  // MARK: - Child Views

  struct DetailView: View {
    let store: StoreOf<NavigationLinkSelectionExample.Detail>

    var body: some View {
      VStack {
        WithViewStore(store.scope(state: \.item)) { viewStore in
          Text("Item \(viewStore.id)").padding()
        }

        TimerExampleView(store: store.scope(
          state: \.timer,
          action: NavigationLinkSelectionExample.Detail.Action.timer
        ))

        Button(action: { ViewStore(store.stateless).send(.didTapDismissButton) }) {
          Text("Dismiss").padding()
        }
      }
      .navigationTitle("Detail")
    }
  }
}

struct NavigationLinkSelectionExample_Previews: PreviewProvider {
  static var previews: some View {
    NavigationLinkSelectionExampleView(store: Store(
      initialState: NavigationLinkSelectionExample.State(),
      reducer: NavigationLinkSelectionExample()
    ))
  }
}
