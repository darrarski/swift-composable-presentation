import ComposableArchitecture
import SwiftUI

struct TimerExample: ReducerProtocol {
  struct State: Identifiable {
    struct ID: Hashable {
      var uuid = UUID()
    }

    let id = ID()
    var count: Int = 0
  }

  enum Action {
    case start
    case tick
  }

  func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case .start:
      // NB: Clocks are available on iOS ≥ 16
      return EffectTask.timer(id: state.id, every: .seconds(1), on: DispatchQueue.main)
        .map { _ in .tick }

    case .tick:
      state.count += 1
      return .none
    }
  }
}

struct TimerExampleView: View {
  let store: StoreOf<TimerExample>

  var body: some View {
    WithViewStore(store, observe: \.count) { viewStore in
      Text("\(viewStore.state)")
        .onAppear { viewStore.send(.start) }
    }
  }
}
