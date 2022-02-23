import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct PopToRootExample: View {
  struct RootState {
    var timer = TimerState()
    var first: FirstState?
  }

  enum RootAction {
    case didTapPushFirst
    case didDismissFirst
    case timer(TimerAction)
    case first(FirstAction)
  }

  static let rootReducer = Reducer<RootState, RootAction, Void>.combine(
    timerReducer.pullback(
      state: \.timer,
      action: /RootAction.timer,
      environment: { () }
    ),

    Reducer { state, action, _ in
      switch action {
      case .didTapPushFirst:
        state.first = FirstState()
        return .none

      case .didDismissFirst:
        state.first = nil
        return .none

      case .timer(_):
        return .none

      case .first(.second(.didTapPopToRoot)):
        state.first = nil
        return .none

      case .first(_):
        return .none
      }
    }
  ).presenting(
    Self.firstReducer,
    state: .keyPath(\.first),
    id: .notNil(),
    action: /RootAction.first,
    environment: { () }
  )

  struct RootView: View {
    let store: Store<RootState, RootAction>

    var body: some View {
      VStack {
        TimerView(store: store.scope(
          state: \.timer,
          action: RootAction.timer
        ))

        NavigationLinkWithStore(
          store.scope(
            state: \.first,
            action: RootAction.first
          ),
          mapState: replayNonNil(),
          setActive: { active in
            let viewStore = ViewStore(store.stateless)
            viewStore.send(active ? .didTapPushFirst : .didDismissFirst)
          },
          destination: FirstView.init(store:),
          label: {
            Text("Push First").padding()
          }
        )
      }
      .navigationTitle("Root")
    }
  }

  struct FirstState {
    var timer = TimerState()
    var second: SecondState?
  }

  enum FirstAction {
    case didTapPushSecond
    case didDismissSecond
    case timer(TimerAction)
    case second(SecondAction)
  }

  static let firstReducer = Reducer<FirstState, FirstAction, Void>.combine(
    timerReducer.pullback(
      state: \.timer,
      action: /FirstAction.timer,
      environment: { () }
    ),

    Reducer { state, action, _ in
      switch action {
      case .didTapPushSecond:
        state.second = SecondState()
        return .none

      case .didDismissSecond:
        state.second = nil
        return .none

      case .timer(_):
        return .none

      case .second(_):
        return .none
      }
    }
  ).presenting(
    Self.secondReducer,
    state: .keyPath(\.second),
    id: .notNil(),
    action: /FirstAction.second,
    environment: { () }
  )

  struct FirstView: View {
    let store: Store<FirstState, FirstAction>

    var body: some View {
      VStack {
        TimerView(store: store.scope(
          state: \.timer,
          action: FirstAction.timer
        ))

        NavigationLinkWithStore(
          store.scope(
            state: \.second,
            action: FirstAction.second
          ),
          mapState: replayNonNil(),
          setActive: { active in
            let viewStore = ViewStore(store.stateless)
            viewStore.send(active ? .didTapPushSecond : .didDismissSecond)
          },
          destination: SecondView.init(store:),
          label: {
            Text("Push Second").padding()
          }
        )
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(.secondarySystemBackground).ignoresSafeArea())
      .navigationTitle("First")
    }
  }

  struct SecondState {
    var timer = TimerState()
  }

  enum SecondAction {
    case didTapPopToRoot
    case timer(TimerAction)
  }

  static let secondReducer = Reducer<SecondState, SecondAction, Void>.combine(
    timerReducer.pullback(
      state: \.timer,
      action: /SecondAction.timer,
      environment: { () }
    ),

    Reducer { state, action, _ in
      switch action {
      case .didTapPopToRoot:
        return .none

      case .timer(_):
        return .none
      }
    }
  )

  struct SecondView: View {
    let store: Store<SecondState, SecondAction>

    var body: some View {
      VStack {
        TimerView(store: store.scope(
          state: \.timer,
          action: SecondAction.timer
        ))

        Button(action: { ViewStore(store.stateless).send(.didTapPopToRoot) }) {
          Text("Pop to root").padding()
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(.tertiarySystemBackground).ignoresSafeArea())
      .navigationTitle("Second")
    }
  }

  var body: some View {
    NavigationView {
      RootView(store: Store(
        initialState: RootState(),
        reducer: Self.rootReducer.debug(),
        environment: ()
      ))
    }
    .navigationViewStyle(StackNavigationViewStyle())
  }
}

struct PopToRootExample_Previews: PreviewProvider {
  static var previews: some View {
    PopToRootExample()
  }
}
