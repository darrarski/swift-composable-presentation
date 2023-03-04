import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct PopToRootExample: Reducer {
  struct State {
    var timer = TimerExample.State()
    var first: First.State?
  }

  enum Action {
    case didTapPushFirst
    case didDismissFirst
    case timer(TimerExample.Action)
    case first(First.Action)
  }

  var body: some Reducer<State, Action> {
    Scope(state: \.timer, action: /Action.timer) {
      TimerExample()
    }

    Reduce { state, action in
      switch action {
      case .didTapPushFirst:
        state.first = First.State()
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
    .presenting(
      state: .keyPath(\.first),
      id: .notNil(),
      action: /Action.first,
      presented: First.init
    )
  }

  // MARK: - Child Reducers

  struct First: Reducer {
    struct State {
      var timer = TimerExample.State()
      var second: Second.State?
    }

    enum Action {
      case didTapPushSecond
      case didDismissSecond
      case timer(TimerExample.Action)
      case second(Second.Action)
    }

    var body: some Reducer<State, Action> {
      Scope(state: \.timer, action: /Action.timer) {
        TimerExample()
      }

      Reduce { state, action in
        switch action {
        case .didTapPushSecond:
          state.second = Second.State()
          return .none

        case .didDismissSecond:
          state.second = nil
          return .none

        case .timer(_), .second(_):
          return .none
        }
      }
      .presenting(
        state: .keyPath(\.second),
        id: .notNil(),
        action: /First.Action.second,
        presented: Second.init
      )
    }
  }

  struct Second: Reducer {
    struct State {
      var timer = TimerExample.State()
    }

    enum Action {
      case didTapPopToRoot
      case timer(TimerExample.Action)
    }

    var body: some Reducer<State, Action> {
      Scope(state: \.timer, action: /Action.timer) {
        TimerExample()
      }

      Reduce { state, action in
        switch action {
        case .didTapPopToRoot:
          return .none

        case .timer(_):
          return .none
        }
      }
    }
  }
}

struct PopToRootExampleView: View {
  let store: StoreOf<PopToRootExample>

  var body: some View {
    _NavigationStack {
      VStack {
        TimerExampleView(store: store.scope(
          state: \.timer,
          action: PopToRootExample.Action.timer
        ))

        Button {
          ViewStore(store.stateless).send(.didTapPushFirst)
        } label: {
          Text("Push First").padding()
        }
        ._navigationDestination(
          store.scope(
            state: \.first,
            action: PopToRootExample.Action.first
          ),
          mapState: replayNonNil(),
          onDismiss: { ViewStore(store.stateless).send(.didDismissFirst) },
          destination: FirstView.init(store:)
        )
      }
      .navigationTitle("PopToRootExample")
    }
  }

  // MARK: - Child Views

  struct FirstView: View {
    let store: StoreOf<PopToRootExample.First>

    var body: some View {
      VStack {
        TimerExampleView(store: store.scope(
          state: \.timer,
          action: PopToRootExample.First.Action.timer
        ))

        Button {
          ViewStore(store.stateless).send(.didTapPushSecond)
        } label: {
          Text("Push Second").padding()
        }
        ._navigationDestination(
          store.scope(
            state: \.second,
            action: PopToRootExample.First.Action.second
          ),
          mapState: replayNonNil(),
          onDismiss: { ViewStore(store.stateless).send(.didDismissSecond) },
          destination: SecondView.init(store:)
        )
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(.secondarySystemBackground).ignoresSafeArea())
      .navigationTitle("First")
    }
  }

  struct SecondView: View {
    let store: StoreOf<PopToRootExample.Second>

    var body: some View {
      VStack {
        TimerExampleView(store: store.scope(
          state: \.timer,
          action: PopToRootExample.Second.Action.timer
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
}

struct PopToRootExample_Previews: PreviewProvider {
  static var previews: some View {
    PopToRootExampleView(store: Store(
      initialState: PopToRootExample.State(),
      reducer: PopToRootExample()
    ))
  }
}
