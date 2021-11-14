import ComposableArchitecture
import SwiftUI

struct TimerState: Identifiable {
  struct ID: Hashable {
    var uuid = UUID()
  }

  let id = ID()
  var count: Int = 0
}

enum TimerAction {
  case didAppear
  case didTick
}

let timerReducer = Reducer<TimerState, TimerAction, Void> { state, action, _ in
  switch action {
  case .didAppear:
    return Effect.timer(id: state.id, every: .seconds(1), on: DispatchQueue.main)
      .map { _ in .didTick }

  case .didTick:
    state.count += 1
    return .none
  }
}

struct TimerView: View {
  let store: Store<TimerState, TimerAction>

  var body: some View {
    WithViewStore(store.scope(state: \.count)) { viewStore in
      Text("\(viewStore.state)")
        .onAppear { viewStore.send(.didAppear) }
    }
  }
}
