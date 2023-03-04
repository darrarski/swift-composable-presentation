import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct NavigationDestinationExample: Reducer {
  struct State {
    var detail: Detail.State?
  }

  enum Action {
    case didTapDetailButton
    case didDismissDetail
    case detail(Detail.Action)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .didTapDetailButton:
        state.detail = Detail.State()
        return .none

      case .didDismissDetail, .detail(.didTapDismissButton):
        state.detail = nil
        return .none

      case .detail(_):
        return .none
      }
    }
    .presenting(
      state: .keyPath(\.detail),
      id: .notNil(),
      action: /Action.detail,
      presented: Detail.init
    )
  }

  // MARK: - Child Reducers

  struct Detail: Reducer {
    struct State {
      var timer = TimerExample.State()
    }

    enum Action {
      case didTapDismissButton
      case timer(TimerExample.Action)
    }

    var body: some Reducer<State, Action> {
      Scope(state: \.timer, action: /Action.timer) {
        TimerExample()
      }
    }
  }
}

struct NavigationDestinationExampleView: View {
  let store: StoreOf<NavigationDestinationExample>

  var body: some View {
    WithViewStore(store.stateless) { viewStore in
      _NavigationStack {
        Button {
          viewStore.send(.didTapDetailButton)
        } label: {
          Text("Detail").padding()
        }
        ._navigationDestination(
          store.scope(
            state: \.detail,
            action: NavigationDestinationExample.Action.detail
          ),
          onDismiss: {
            viewStore.send(.didDismissDetail)
          },
          destination: DetailView.init(store:)
        )
      }
      .navigationTitle("NavigationDestinationExample")
    }
  }

  // MARK: - Child Views

  struct DetailView: View {
    let store: StoreOf<NavigationDestinationExample.Detail>

    var body: some View {
      VStack {
        TimerExampleView(store: store.scope(
          state: \.timer,
          action: NavigationDestinationExample.Detail.Action.timer
        ))

        Button(action: { ViewStore(store.stateless).send(.didTapDismissButton) }) {
          Text("Dismiss").padding()
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(.secondarySystemBackground).ignoresSafeArea())
      .navigationTitle("Detail")
    }
  }
}

struct NavigationDestinationExample_Previews: PreviewProvider {
  static var previews: some View {
    NavigationDestinationExampleView(store: Store(
      initialState: NavigationDestinationExample.State(),
      reducer: NavigationDestinationExample()
    ))
  }
}
