import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct ForEachStoreExample: ReducerProtocol {
  struct State {
    var timers: IdentifiedArrayOf<TimerExample.State> = []
  }

  enum Action {
    case didTapAddTimer
    case didTapDeleteTimer(id: TimerExample.State.ID)
    case timer(id: TimerExample.State.ID, action: TimerExample.Action)
  }

  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case .didTapAddTimer:
        state.timers.insert(TimerExample.State(), at: state.timers.startIndex)
        return .none

      case let .didTapDeleteTimer(id):
        state.timers.remove(id: id)
        return .none

      case .timer(_, _):
        return .none
      }
    }
    .presentingForEach(
      presentationID: ObjectIdentifier(ForEachStoreExample.self),
      state: \.timers,
      action: /Action.timer(id:action:),
      element: TimerExample.init
    )
  }
}

struct ForEachStoreExampleView: View {
  let store: StoreOf<ForEachStoreExample>

  var body: some View {
    WithViewStore(store.stateless) { viewStore in
      VStack {
        Button(action: { viewStore.send(.didTapAddTimer, animation: .default) }) {
          Text("Add timer").padding()
        }
        ScrollView {
          LazyVStack {
            ForEachStore(
              store.scope(
                state: \.timers,
                action: ForEachStoreExample.Action.timer(id:action:)
              ),
              content: { timerStore in
                HStack {
                  TimerExampleView(store: timerStore)

                  Spacer()

                  Button(action: {
                    let timerId = ViewStore(timerStore.scope(state: \.id)).state
                    let viewStore = ViewStore(store.stateless)
                    viewStore.send(.didTapDeleteTimer(id: timerId), animation: .default)
                  }) {
                    Text("Delete").padding()
                  }
                }
                .padding()
              }
            )
          }
        }
      }
    }
  }
}

struct ForEachStoreExample_Previews: PreviewProvider {
  static var previews: some View {
    ForEachStoreExampleView(store: Store(
      initialState: ForEachStoreExample.State(),
      reducer: ForEachStoreExample()
    ))
  }
}
