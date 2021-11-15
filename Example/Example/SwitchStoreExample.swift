import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct SwitchStoreExample: View {
  enum MainState: Identifiable {
    case first(FirstState)
    case second(SecondState)

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

  enum MainAction {
    case set(id: MainState.ID)
    case first(FirstAction)
    case second(SecondAction)
  }

  static let mainReducer = Reducer<MainState, MainAction, Void> { state, action, _ in
    switch action {
    case let .set(id):
      switch id {
      case .first:
        state = .first(FirstState())
      case .second:
        state = .second(SecondState())
      }
      return .none

    case .first(_):
      return .none

    case .second(_):
      return .none
    }
  }.presenting(
    firstReducer,
    state: /MainState.first,
    action: /MainAction.first,
    environment: { () }
  ).presenting(
    secondReducer,
    state: /MainState.second,
    action: /MainAction.second,
    environment: { () }
  )

  struct MainView: View {
    let store: Store<MainState, MainAction>

    var body: some View {
      VStack {
        WithViewStore(store.scope(state: \.id)) { viewStore in
          Picker("", selection: viewStore.binding(send: MainAction.set(id:))) {
            Text("First").tag(MainState.ID.first)
            Text("Second").tag(MainState.ID.second)
          }
          .pickerStyle(SegmentedPickerStyle())
        }

        SwitchStore(store) {
          CaseLet(
            state: /MainState.first,
            action: MainAction.first,
            then: FirstView.init(store:)
          )
          CaseLet(
            state: /MainState.second,
            action: MainAction.second,
            then: SecondView.init(store:)
          )
        }
        .frame(maxWidth: .infinity)
        .border(Color.primary, width: 1)
      }
      .padding()
    }
  }

  struct FirstState {
    var timer = TimerState()
  }

  enum FirstAction {
    case timer(TimerAction)
  }

  static let firstReducer = Reducer<FirstState, FirstAction, Void>.combine(
    timerReducer.pullback(
      state: \.timer,
      action: /FirstAction.timer,
      environment: { () }
    )
  )

  struct FirstView: View {
    let store: Store<FirstState, FirstAction>

    var body: some View {
      VStack {
        Text("First").font(.title)

        TimerView(store: store.scope(
          state: \.timer,
          action: FirstAction.timer
        ))
      }
      .padding()
    }
  }

  struct SecondState {
    var timer = TimerState()
  }

  enum SecondAction {
    case timer(TimerAction)
  }

  static let secondReducer = Reducer<SecondState, SecondAction, Void>.combine(
    timerReducer.pullback(
      state: \.timer,
      action: /SecondAction.timer,
      environment: { () }
    )
  )

  struct SecondView: View {
    let store: Store<SecondState, SecondAction>

    var body: some View {
      VStack {
        Text("Second").font(.title)

        TimerView(store: store.scope(
          state: \.timer,
          action: SecondAction.timer
        ))
      }
      .padding()
    }
  }

  var body: some View {
    MainView(store: Store(
      initialState: MainState.first(FirstState()),
      reducer: Self.mainReducer,
      environment: ()
    ))
  }
}

struct SwitchStoreExample_Previews: PreviewProvider {
  static var previews: some View {
    SwitchStoreExample()
  }
}
