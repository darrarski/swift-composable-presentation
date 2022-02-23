import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct NavigationLinkSelectionExample: View {
  struct Item: Identifiable, Equatable {
    var id: String
  }

  struct MasterState {
    var items: [Item]
    var detail: DetailState? = nil
  }

  enum MasterAction {
    case didSelect(itemId: Item.ID?)
    case detail(DetailAction)
  }

  static let masterReducer = Reducer<MasterState, MasterAction, Void> { state, action, _ in
    switch action {
    case .didSelect(.some(let itemId)):
      state.detail = state.items
        .first { $0.id == itemId }
        .map(DetailState.init(item:))
      return .none

    case .didSelect(.none), .detail(.didTapDismissButton):
      state.detail = nil
      return .none

    case .detail(_):
      return .none
    }
  }
    .presenting(
      detailReducer,
      state: .keyPath(\.detail),
      id: .keyPath(\.?.item.id),
      action: /MasterAction.detail,
      environment: { () }
    )

  struct MasterView: View {
    let store: Store<MasterState, MasterAction>

    struct ViewState: Equatable {
      let items: [Item]
      let selectedItemID: Item.ID?

      init(_ state: MasterState) {
        items = state.items
        selectedItemID = state.detail?.item.id
      }
    }

    var body: some View {
      WithViewStore(store.scope(state: ViewState.init)) { viewStore in
        List {
          ForEach(viewStore.items) { item in
            NavigationLink(
              tag: item.id,
              selection: viewStore.binding(
                get: \.selectedItemID,
                send: MasterAction.didSelect
              ),
              destination: {
                IfLetStore(
                  store.scope(
                    state: \.detail,
                    action: MasterAction.detail
                  ),
                  then: DetailView.init(store:)
                )
              },
              label: { Text("Item \(item.id)") }
            )
          }
        }
        .navigationTitle("Master")
      }
    }
  }

  struct DetailState {
    init(item: Item) {
      self.item = item
    }

    var item: Item
    var timer = TimerState()
  }

  enum DetailAction {
    case didTapDismissButton
    case timer(TimerAction)
  }

  static let detailReducer = Reducer<DetailState, DetailAction, Void>.combine(
    timerReducer.pullback(
      state: \.timer,
      action: /DetailAction.timer,
      environment: { () }
    )
  )

  struct DetailView: View {
    let store: Store<DetailState, DetailAction>

    var body: some View {
      VStack {
        WithViewStore(store.scope(state: \.item)) { viewStore in
          Text("Item \(viewStore.id)").padding()
        }

        TimerView(store: store.scope(
          state: \.timer,
          action: DetailAction.timer
        ))

        Button(action: { ViewStore(store.stateless).send(.didTapDismissButton) }) {
          Text("Dismiss").padding()
        }
      }
      .navigationTitle("Detail")
    }
  }

  var body: some View {
    NavigationView {
      MasterView(store: Store(
        initialState: MasterState(items: [
          Item(id: "A"),
          Item(id: "B"),
          Item(id: "C"),
        ]),
        reducer: Self.masterReducer.debug(),
        environment: ()
      ))
    }
  }
}

struct NavigationLinkSelectionExample_Previews: PreviewProvider {
  static var previews: some View {
    NavigationLinkSelectionExample()
  }
}
