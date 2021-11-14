import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct ForEachStoreExample: View {
  struct ListState {
    var timers: IdentifiedArrayOf<TimerState> = []
  }

  enum ListAction {
    case didTapAddTimer
    case didTapDeleteTimer(id: TimerState.ID)
    case timer(id: TimerState.ID, action: TimerAction)
  }

  static let listReducer = Reducer<ListState, ListAction, Void> { state, action, _ in
    switch action {
    case .didTapAddTimer:
      state.timers.insert(TimerState(), at: state.timers.startIndex)
      return .none

    case let .didTapDeleteTimer(id):
      state.timers.remove(id: id)
      return .none

    case .timer(_, _):
      return .none
    }
  }.presenting(
    forEach: timerReducer,
    state: \.timers,
    action: /ListAction.timer(id:action:),
    environment: { () }
  )

  struct ListView: View {
    let store: Store<ListState, ListAction>

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
                  action: ListAction.timer(id:action:)
                ),
                content: { timerStore in
                  HStack {
                    TimerView(store: timerStore)

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

  var body: some View {
    ListView(store: Store(
      initialState: ListState(timers: [TimerState()]),
      reducer: Self.listReducer,
      environment: ()
    ))
  }
}


struct ForEachStoreExample_Previews: PreviewProvider {
  static var previews: some View {
    ForEachStoreExample()
  }
}
