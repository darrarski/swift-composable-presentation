import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct DestinationExample: View {
  // MARK: - Reducers

  struct Main: ReducerProtocol {
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
      case alert(Main.Action.Alert)
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
        presentationID: Presentation.first,
        unwrapping: \.destination,
        case: /State.Destination.first,
        id: .notNil(),
        action: /Action.first,
        presented: { First() }
      )
      .presenting(
        presentationID: Presentation.second,
        unwrapping: \.destination,
        case: /State.Destination.second,
        id: .notNil(),
        action: /Action.second,
        presented: { Second() }
      )
    }
  }

  struct First: ReducerProtocol {
    struct State {
      var timer = TimerState()
    }

    enum Action {
      case timer(TimerAction)
    }

    var body: some ReducerProtocol<State, Action> {
      Scope(state: \.timer, action: /Action.timer) {
        Reduce(timerReducer, environment: ())
      }
    }
  }

  struct Second: ReducerProtocol {
    struct State {
      var timer = TimerState()
    }

    enum Action {
      case timer(TimerAction)
    }

    var body: some ReducerProtocol<State, Action> {
      Scope(state: \.timer, action: /Action.timer) {
        Reduce(timerReducer, environment: ())
      }
    }
  }

  // MARK: - Views

  struct MainView: View {
    let store: StoreOf<Main>

    var body: some View {
      WithViewStore(store.stateless) { viewStore in
        NavigationViewWrapper {
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

            Button {
              viewStore.send(.alertButtonTapped)
            } label: {
              Text("→ Alert")
                .padding()
            }
          }
          .padding()
          .sheet(
            store.scope(
              state: { (/Main.State.Destination.first).extract(from: $0.destination) },
              action: Main.Action.first
            ),
            onDismiss: { viewStore.send(.didDismissFirst) },
            content: FirstView.init(store:)
          )
          .modifier(NavigationLinkWrapper(
            store: store.scope(
              state: { (/Main.State.Destination.second).extract(from: $0.destination) },
              action: Main.Action.second
            ),
            onDeactivate: { viewStore.send(.didDismissSecond) },
            destination: SecondView.init(store:)
          ))
          .alert(
            store.scope(
              state: { (/Main.State.Destination.alert).extract(from: $0.destination) },
              action: Main.Action.alert
            ),
            dismiss: .dismissed
          )
        }
      }
    }
  }

  struct FirstView: View {
    let store: StoreOf<First>

    var body: some View {
      VStack {
        Text("First").font(.title)

        TimerView(store: store.scope(
          state: \.timer,
          action: First.Action.timer
        ))
      }
      .padding()
    }
  }

  struct SecondView: View {
    let store: StoreOf<Second>

    var body: some View {
      VStack {
        Text("Second").font(.title)

        TimerView(store: store.scope(
          state: \.timer,
          action: Second.Action.timer
        ))
      }
      .padding()
    }
  }

  struct NavigationViewWrapper<Content: View>: View {
    let content: () -> Content

    var body: some View {
      if #available(iOS 16.0, *) {
        NavigationStack(root: content)
      } else {
        NavigationView(content: content)
      }
    }
  }

  struct NavigationLinkWrapper<State, Action, Destination: View>: ViewModifier {
    let store: Store<State?, Action>
    let onDeactivate: () -> Void
    let destination: (Store<State, Action>) -> Destination

    func body(content: Content) -> some View {
      if #available(iOS 16.0, *) {
        content.navigationDestination(
          store,
          onDismiss: onDeactivate,
          content: destination
        )
      } else {
        content.background(
          NavigationLinkWithStore(
            store,
            onDeactivate: onDeactivate,
            destination: destination
          )
        )
      }
    }
  }

  var body: some View {
    MainView(store: Store(
      initialState: Main.State(),
      reducer: Main()._printChanges()
    ))
  }
}

struct DestinationExample_Previews: PreviewProvider {
  static var previews: some View {
    DestinationExample()
  }
}
