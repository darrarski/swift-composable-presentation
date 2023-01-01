import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct DestinationExample: ReducerProtocol {
  struct State {
    enum Destination {
      case first(First.State)
      case second(Second.State)
      case alert(AlertState<Action.Alert>)
    }

    var destination: Destination?
  }

  enum Action {
    enum Alert {
      case firstTapped
      case secondTapped
      case dismissed
    }

    case firstButtonTapped
    case secondButtonTapped
    case alertButtonTapped
    case didDismissFirst
    case didDismissSecond
    case first(First.Action)
    case second(Second.Action)
    case alert(Action.Alert)
  }

  enum Presentation: Hashable {
    case first
    case second
  }

  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case .firstButtonTapped, .alert(.firstTapped):
        state.destination = .first(First.State())
        return .none

      case .secondButtonTapped, .alert(.secondTapped):
        state.destination = .second(Second.State())
        return .none

      case .alertButtonTapped:
        if #available(iOS 15.0, *) {
          state.destination = .alert(AlertState(
            title: { TextState("Title") },
            actions: {
              let actions: [ButtonState<Action.Alert>] = [
                ButtonState(action: .firstTapped) {
                  TextState("Present first")
                },
                ButtonState(action: .secondTapped) {
                  TextState("Present second")
                },
                ButtonState.cancel(TextState("Cancel"))
              ]
              return actions
            },
            message: { TextState("Message") }
          ))
        }
        return .none

      case .didDismissFirst:
        if (/State.Destination.first).extract(from: state.destination) != nil {
          state.destination = nil
        }
        return .none

      case .didDismissSecond:
        if (/State.Destination.second).extract(from: state.destination) != nil {
          state.destination = nil
        }
        return .none

      case .alert(.dismissed):
        if (/State.Destination.alert).extract(from: state.destination) != nil {
          state.destination = nil
        }
        return .none

      case .first, .second:
        return .none
      }
    }
    .presenting(
      presentationID: .static(Presentation.first),
      unwrapping: \.destination,
      case: /State.Destination.first,
      id: .notNil(),
      action: /Action.first,
      presented: { First() }
    )
    .presenting(
      presentationID: .static(Presentation.second),
      unwrapping: \.destination,
      case: /State.Destination.second,
      id: .notNil(),
      action: /Action.second,
      presented: { Second() }
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

struct DestinationExampleView: View {
  let store: StoreOf<DestinationExample>

  var body: some View {
    WithViewStore(store.stateless) { viewStore in
      _NavigationStack {
        VStack(alignment: .leading, spacing: 0) {
          Button {
            viewStore.send(.firstButtonTapped)
          } label: {
            Text("→ First (sheet)")
              .padding()
          }

          Button {
            viewStore.send(.secondButtonTapped)
          } label: {
            Text("→ Second (navigation link)")
              .padding()
          }

          if #available(iOS 15.0, *) {
            Button {
              viewStore.send(.alertButtonTapped)
            } label: {
              Text("→ Alert")
                .padding()
            }
            .alert(
              store.scope(
                state: { (/DestinationExample.State.Destination.alert).extract(from: $0.destination) },
                action: DestinationExample.Action.alert
              ),
              dismiss: .dismissed
            )
          }
        }
        .padding()
        .sheet(
          store.scope(
            state: { (/DestinationExample.State.Destination.first).extract(from: $0.destination) },
            action: DestinationExample.Action.first
          ),
          onDismiss: { viewStore.send(.didDismissFirst) },
          content: FirstView.init(store:)
        )
        ._navigationDestination(
          store.scope(
            state: { (/DestinationExample.State.Destination.second).extract(from: $0.destination) },
            action: DestinationExample.Action.second
          ),
          onDismiss: { viewStore.send(.didDismissSecond) },
          destination: SecondView.init(store:)
        )
      }
    }
  }

  // MARK: - Child Views

  struct FirstView: View {
    let store: StoreOf<DestinationExample.First>

    var body: some View {
      VStack {
        Text("First").font(.title)

        TimerExampleView(store: store.scope(
          state: \.timer,
          action: DestinationExample.First.Action.timer
        ))
      }
      .padding()
    }
  }

  struct SecondView: View {
    let store: StoreOf<DestinationExample.Second>

    var body: some View {
      VStack {
        Text("Second").font(.title)

        TimerExampleView(store: store.scope(
          state: \.timer,
          action: DestinationExample.Second.Action.timer
        ))
      }
      .padding()
    }
  }
}

struct DestinationExample_Previews: PreviewProvider {
  static var previews: some View {
    DestinationExampleView(store: Store(
      initialState: DestinationExample.State(),
      reducer: DestinationExample()
    ))
  }
}
