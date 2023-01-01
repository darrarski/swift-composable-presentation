import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct NavigationLinkExample: ReducerProtocol {
  struct State {
    var detail: Detail.State?
  }

  enum Action {
    case didTapDetailButton
    case didDismissDetail
    case detail(Detail.Action)
  }

  var body: some ReducerProtocol<State, Action> {
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
      presentationID: ObjectIdentifier(NavigationLinkExample.self),
      state: .keyPath(\.detail),
      id: .notNil(),
      action: /Action.detail,
      presented: Detail.init
    )
  }

  // MARK: - Child Reducers

  struct Detail: ReducerProtocol {
    struct State {
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

struct NavigationLinkExampleView: View {
  let store: StoreOf<NavigationLinkExample>

  var body: some View {
    WithViewStore(store.stateless) { viewStore in
      NavigationView {
        NavigationLinkWithStore(
          store.scope(
            state: \.detail,
            action: NavigationLinkExample.Action.detail
          ),
          setActive: { active in
            viewStore.send(active ? .didTapDetailButton : .didDismissDetail)
          },
          destination: DetailView.init(store:),
          label: { Text("Detail").padding() }
        )
      }
      .navigationTitle("NavigationLinkExample")
    }
  }

  // MARK: - Child Views

  struct DetailView: View {
    let store: StoreOf<NavigationLinkExample.Detail>

    var body: some View {
      VStack {
        TimerExampleView(store: store.scope(
          state: \.timer,
          action: NavigationLinkExample.Detail.Action.timer
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

struct NavigationLinkExample_Previews: PreviewProvider {
  static var previews: some View {
    NavigationLinkExampleView(store: Store(
      initialState: NavigationLinkExample.State(),
      reducer: NavigationLinkExample()
    ))
  }
}
