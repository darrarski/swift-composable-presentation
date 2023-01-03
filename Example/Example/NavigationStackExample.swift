import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct NavigationStackExample: ReducerProtocol {
  struct State {
    var detail: Detail.State?
  }

  enum Action {
    case push(Detail.State)
    case pop
    case detail(Detail.Action)
  }

  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case .push(let detail):
        state.detail = detail
        return .none

      case .pop, .detail(.didTapDismiss):
        state.detail = nil
        return .none

      case .detail(_):
        return .none
      }
    }
    .presenting(
      state: .keyPath(\.detail),
      id: .keyPath(\.?.id),
      action: /Action.detail,
      presented: Detail.init
    )
  }

  // MARK: - Child Reducers

  struct Detail: ReducerProtocol {
    struct State: Identifiable {
      var id: String
      var timer = TimerExample.State()
    }

    enum Action {
      case didTapDismiss
      case timer(TimerExample.Action)
    }

    var body: some ReducerProtocol<State, Action> {
      Scope(state: \.timer, action: /Action.timer) {
        TimerExample()
      }
    }
  }
}

struct NavigationStackExampleView: View {
  let store: StoreOf<NavigationStackExample>

  var body: some View {
    if #available(iOS 16, *) {
      WithViewStore(store.stateless) { viewStore in
        NavigationStack {
          VStack {
            Button(action: { viewStore.send(.push(.init(id: "A"))) }) {
              Text("Push A")
            }

            Button(action: { viewStore.send(.push(.init(id: "B"))) }) {
              Text("Push B")
            }

            Button(action: { viewStore.send(.push(.init(id: "C"))) }) {
              Text("Push C")
            }
          }
          .navigationTitle("Root")
          .navigationDestination(
            store.scope(
              state: \.detail,
              action: NavigationStackExample.Action.detail
            ),
            mapState: replayNonNil(),
            onDismiss: { viewStore.send(.pop) },
            content: DetailView.init(store:)
          )
        }
      }
    } else {
      Text("iOS ≥ 16 required")
    }
  }

  // MARK: - Child Views

  struct DetailView: View {
    let store: StoreOf<NavigationStackExample.Detail>

    struct ViewState: Equatable {
      init(state: NavigationStackExample.Detail.State) {
        id = state.id
      }

      var id: String
    }

    var body: some View {
      WithViewStore(store, observe: ViewState.init) { viewStore in
        VStack {
          TimerExampleView(store: store.scope(
            state: \.timer,
            action: NavigationStackExample.Detail.Action.timer
          ))

          Button(action: { viewStore.send(.didTapDismiss) }) {
            Text("Dismiss").padding()
          }
        }
        .navigationTitle(viewStore.id)
      }
    }
  }
}

struct NavigationStackExample_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStackExampleView(store: Store(
      initialState: NavigationStackExample.State(),
      reducer: NavigationStackExample()
    ))
  }
}
