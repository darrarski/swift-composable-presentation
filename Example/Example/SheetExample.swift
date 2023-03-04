import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct SheetExample: ReducerProtocol {
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

      case .didDismissDetail:
        state.detail = nil
        return .none

      case .detail(.didTapDismiss):
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

  struct Detail: ReducerProtocol {
    struct State {
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

struct SheetExampleView: View {
  let store: StoreOf<SheetExample>

  var body: some View {
    Button {
      ViewStore(store.stateless).send(.didTapDetailButton)
    } label: {
      Text("Detail")
    }
    .sheet(
      store.scope(
        state: \.detail,
        action: SheetExample.Action.detail
      ),
      mapState: replayNonNil(),
      onDismiss: { ViewStore(store.stateless).send(.didDismissDetail) },
      content: DetailView.init(store:)
    )
  }

  // MARK: - Child Views

  struct DetailView: View {
    let store: StoreOf<SheetExample.Detail>

    var body: some View {
      VStack {
        TimerExampleView(store: store.scope(
          state: \.timer,
          action: SheetExample.Detail.Action.timer
        ))

        Button(action: { ViewStore(store.stateless).send(.didTapDismiss) }) {
          Text("Dismiss").padding()
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(.secondarySystemBackground).ignoresSafeArea())
    }
  }
}

struct SheetExample_Previews: PreviewProvider {
  static var previews: some View {
    SheetExampleView(store: Store(
      initialState: SheetExample.State(),
      reducer: SheetExample()
    ))
  }
}
