import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct FullScreenCoverExample: ReducerProtocol {
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

      case .detail(_):
        return .none
      }
    }
    .presenting(
      presentationID: ObjectIdentifier(FullScreenCoverExample.self),
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

struct FullScreenCoverExampleView: View {
  let store: StoreOf<FullScreenCoverExample>

  var body: some View {
    WithViewStore(store.stateless) { viewStore in
      Button(action: { viewStore.send(.didTapDetailButton) }) {
        Text("Detail")
      }
      .fullScreenCover(
        store.scope(
          state: \.detail,
          action: FullScreenCoverExample.Action.detail
        ),
        mapState: replayNonNil(),
        onDismiss: { viewStore.send(.didDismissDetail) },
        content: DetailView.init(store:)
      )
    }
  }

  // MARK: - Child Views

  struct DetailView: View {
    let store: StoreOf<FullScreenCoverExample.Detail>
    @Environment(\.presentationMode) var presentationMode

    init(store: StoreOf<FullScreenCoverExample.Detail>) {
      self.store = store
    }

    var body: some View {
      VStack {
        TimerExampleView(store: store.scope(
          state: \.timer,
          action: FullScreenCoverExample.Detail.Action.timer
        ))

        Button(action: { presentationMode.wrappedValue.dismiss() }) {
          Text("Dismiss").padding()
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(.secondarySystemBackground).ignoresSafeArea())
    }
  }
}

struct FullScreenCoverExample_Previews: PreviewProvider {
  static var previews: some View {
    FullScreenCoverExampleView(store: Store(
      initialState: FullScreenCoverExample.State(),
      reducer: FullScreenCoverExample()
    ))
  }
}
