import ComposableArchitecture
import ComposablePresentation
import SwiftUI

@main
struct App: SwiftUI.App {
  var body: some Scene {
    WindowGroup {
      AppView(store: Store(
        initialState: AppState(),
        reducer: appReducer.debug(),
        environment: ()
      ))
    }
  }
}

struct AppState {
  var first = FirstState()
}

enum AppAction {
  case first(FirstAction)
}

let appReducer = Reducer<AppState, AppAction, Void>.combine(
  firstReducer.pullback(
    state: \.first,
    action: /AppAction.first,
    environment: { $0 }
  ),

  Reducer { state, action, _ in
    switch action {
    case .first(.didTapPresentSecond):
      state.first.second = SecondState()
      return .none

    case .first(.didDismissSecond),
         .first(.second(.didTapDismissSecond)),
         .first(.second(.third(.didTapDismissSecond))):
      state.first.second = nil
      return .none

    case .first(.second(.didTapPresentThird)):
      state.first.second?.third = ThirdState()
      return .none

    case .first(.second(.didDismissThird)),
         .first(.second(.third(.didTapDismissThird))):
      state.first.second?.third = nil
      return .none

    case .first(_):
      return .none
    }
  }
)

struct AppView: View {
  let store: Store<AppState, AppAction>

  var body: some View {
    NavigationView {
      FirstView(store: store.scope(
        state: \.first,
        action: AppAction.first
      ))
    }
    .navigationViewStyle(StackNavigationViewStyle())
  }
}

#if DEBUG
struct AppView_Previews: PreviewProvider {
  static var previews: some View {
    AppView(store: Store(
      initialState: AppState(),
      reducer: appReducer,
      environment: ()
    ))
  }
}
#endif

// MARK: - Timer component

struct TimerState: Identifiable {
  struct ID: Hashable {
    var uuid = UUID()
  }

  let id = ID()
  var seconds: Int = 0
}

enum TimerAction {
  case start
  case tick
}

let timerReducer = Reducer<TimerState, TimerAction, Void> { state, action, _ in
  switch action {
  case .start:
    return Effect.timer(id: state.id, every: 1, on: DispatchQueue.main)
      .map { _ in TimerAction.tick }

  case .tick:
    state.seconds += 1
    return .none
  }
}

struct TimerView: View {
  let store: Store<TimerState, TimerAction>

  var body: some View {
    WithViewStore(store.scope(state: \.seconds)) { viewStore in
      Text("\(viewStore.state)")
        .padding()
        .foregroundColor(.gray)
        .background(Color.white)
        .onAppear { viewStore.send(.start) }
    }
  }
}

// MARK: - First component

struct FirstState {
  var timer = TimerState()
  var second: SecondState?
}

enum FirstAction {
  case didTapPresentSecond
  case didDismissSecond
  case timer(TimerAction)
  case second(SecondAction)
}

let firstReducer = Reducer<FirstState, FirstAction, Void>.combine(
  timerReducer.pullback(
    state: \.timer,
    action: /FirstAction.timer,
    environment: { () }
  )
)
.presents(
  secondReducer.optional(),
  state: \.second,
  action: /FirstAction.second,
  environment: { () }
)

struct FirstView: View {
  let store: Store<FirstState, FirstAction>

  var body: some View {
    WithViewStore(store.stateless) { viewStore in
      VStack {
        TimerView(store: store.scope(
          state: \.timer,
          action: FirstAction.timer
        ))
        .padding()
        
        Button(action: { viewStore.send(.didTapPresentSecond) }) {
          Text("Present Second").padding()
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.orange.ignoresSafeArea())
    .navigationTitle("First")
    .navigationLink(
      store.scope(state: \.second, action: FirstAction.second),
      state: replayNonNil(),
      destination: SecondView.init(store:),
      onDismiss: { ViewStore(store.stateless).send(.didDismissSecond) }
    )
  }
}

// MARK: - Second component

struct SecondState {
  var timer = TimerState()
  var third: ThirdState?
}

enum SecondAction {
  case didTapDismissSecond
  case didTapPresentThird
  case didDismissThird
  case timer(TimerAction)
  case third(ThirdAction)
}

let secondReducer = Reducer<SecondState, SecondAction, Void>.combine(
  timerReducer.pullback(
    state: \.timer,
    action: /SecondAction.timer,
    environment: { $0 }
  )
)
.presents(
  thirdReducer.optional(),
  state: \.third,
  action: /SecondAction.third,
  environment: { () }
)

struct SecondView: View {
  let store: Store<SecondState, SecondAction>

  var body: some View {
    WithViewStore(store.stateless) { viewStore in
      VStack {
        TimerView(store: store.scope(
          state: \.timer,
          action: SecondAction.timer
        ))
        .padding()

        Button(action: { viewStore.send(.didTapDismissSecond) }) {
          Text("Dismiss Second").padding()
        }

        Button(action: { viewStore.send(.didTapPresentThird) }) {
          Text("Present Third").padding()
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.green.ignoresSafeArea())
    .navigationTitle("Second")
    .navigationLink(
      store.scope(state: \.third, action: SecondAction.third),
      state: replayNonNil(),
      destination: ThirdView.init(store:),
      onDismiss: { ViewStore(store.stateless).send(.didDismissThird) }
    )
  }
}

// MARK: - Third component

struct ThirdState {
  var timer = TimerState()
}

enum ThirdAction {
  case didTapDismissSecond
  case didTapDismissThird
  case timer(TimerAction)
}

let thirdReducer = Reducer<ThirdState, ThirdAction, Void>.combine(
  timerReducer.pullback(
    state: \.timer,
    action: /ThirdAction.timer,
    environment: { $0 }
  )
)

struct ThirdView: View {
  let store: Store<ThirdState, ThirdAction>

  var body: some View {
    WithViewStore(store.stateless) { viewStore in
      VStack {
        TimerView(store: store.scope(
          state: \.timer,
          action: ThirdAction.timer
        ))
        .padding()

        Button(action: { viewStore.send(.didTapDismissSecond) }) {
          Text("Dismiss Second").padding()
        }

        Button(action: { viewStore.send(.didTapDismissThird) }) {
          Text("Dismiss Third").padding()
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.ignoresSafeArea())
    .navigationTitle("Third")
  }
}
