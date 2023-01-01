import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct SwitchStoreExample: ReducerProtocol {
  enum State: Identifiable {
    init() {
      self = .first(.init())
    }

    case first(First.State)
    case second(Second.State)

    enum ID: Hashable {
      case first
      case second
    }

    var id: ID {
      switch self {
      case .first(_): return .first
      case .second(_): return .second
      }
    }
  }

  enum Action {
    case set(id: State.ID)
    case first(First.Action)
    case second(Second.Action)
  }

  enum Presentation: Hashable {
    case first
    case second
  }

  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case let .set(id):
        switch id {
        case .first:
          state = .first(First.State())
        case .second:
          state = .second(Second.State())
        }
        return .none

      case .first(_), .second(_):
        return .none
      }
    }
    .presenting(
      presentationID: .value(Presentation.first),
      state: .casePath(/State.first),
      id: .notNil(),
      action: /Action.first,
      presented: First.init
    )
    .presenting(
      presentationID: .value(Presentation.second),
      state: .casePath(/State.second),
      id: .notNil(),
      action: /Action.second,
      presented: Second.init
    )
  }

  // MARK: - Child Reducers

  struct First: ReducerProtocol {
    struct State {
      var timer = TimerExample.State()
    }

    enum Action {
      case timer(TimerExample.Action)
    }

    var body: some ReducerProtocol<State, Action> {
      Scope(state: \.timer, action: /Action.timer) {
        TimerExample()
      }
    }
  }

  struct Second: ReducerProtocol {
    struct State {
      var timer = TimerExample.State()
    }

    enum Action {
      case timer(TimerExample.Action)
    }

    var body: some ReducerProtocol<State, Action> {
      Scope(state: \.timer, action: /Action.timer) {
        TimerExample()
      }
    }
  }
}

struct SwitchStoreExampleView: View {
  let store: StoreOf<SwitchStoreExample>

  var body: some View {
    VStack {
      WithViewStore(store.scope(state: \.id)) { viewStore in
        Picker("", selection: viewStore.binding(send: SwitchStoreExample.Action.set(id:))) {
          Text("First").tag(SwitchStoreExample.State.ID.first)
          Text("Second").tag(SwitchStoreExample.State.ID.second)
        }
        .pickerStyle(SegmentedPickerStyle())
      }

      SwitchStore(store) {
        CaseLet(
          state: /SwitchStoreExample.State.first,
          action: SwitchStoreExample.Action.first,
          then: FirstView.init(store:)
        )
        CaseLet(
          state: /SwitchStoreExample.State.second,
          action: SwitchStoreExample.Action.second,
          then: SecondView.init(store:)
        )
      }
      .frame(maxWidth: .infinity)
      .border(Color.primary, width: 1)
    }
    .padding()
  }

  // MARK: - Child Views

  struct FirstView: View {
    let store: StoreOf<SwitchStoreExample.First>

    var body: some View {
      VStack {
        Text("First").font(.title)

        TimerExampleView(store: store.scope(
          state: \.timer,
          action: SwitchStoreExample.First.Action.timer
        ))
      }
      .padding()
    }
  }

  struct SecondView: View {
    let store: StoreOf<SwitchStoreExample.Second>

    var body: some View {
      VStack {
        Text("Second").font(.title)

        TimerExampleView(store: store.scope(
          state: \.timer,
          action: SwitchStoreExample.Second.Action.timer
        ))
      }
      .padding()
    }
  }
}

struct SwitchStoreExample_Previews: PreviewProvider {
  static var previews: some View {
    SwitchStoreExampleView(store: Store(
      initialState: SwitchStoreExample.State.first(.init()),
      reducer: SwitchStoreExample()
    ))
  }
}
