import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct NavigationStackExample: ReducerProtocol {
  struct State {
    typealias Path = [Destination.State.ID]
    var stack: IdentifiedArrayOf<Destination.State> = []
    var path: Path { Array(stack.ids) }
  }

  enum Action {
    case updatePath(State.Path)
    case start
    case popToRoot
    case popTo(State.Path.Element)
    case destination(_ id: Destination.State.ID, _ action: Destination.Action)
  }

  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case .updatePath(let path):
        state.stack = state.stack.filter { destination in
          path.contains(destination.id)
        }
        return .none

      case .start:
        state.stack = [.init(id: "1")]
        return .none

      case .popTo(let id):
        if let index = state.stack.index(id: id) {
          state.stack = .init(uniqueElements: state.stack[state.stack.startIndex...index])
        }
        return .none

      case .destination(let id, .push(let path)):
        state.stack.append(contentsOf: path.map { .init(id: "\(id).\($0)") })
        return .none

      case .destination(_, .set(let path)):
        state.stack = .init(uniqueElements: path.map { id in
          state.stack[id: id] ?? .init(id: id)
        })
        return .none

      case .destination(_, .pop):
        _ = state.stack.popLast()
        return .none

      case .popToRoot, .destination(_, .popToRoot):
        state.stack.removeAll()
        return .none

      case .destination(_, .shuffle):
        state.stack.shuffle()
        return .none

      case .destination(_, _):
        return .none
      }
    }
    .presentingForEach(
      state: \.stack,
      action: /Action.destination,
      onPresent: .init { id, state in
        // Start timer when destination is added to the stack. When multiple destinations are pushed onto the stack, only the view of the last one will receive `.onAppear` event (that starts the timer too).
        .task { .destination(id, .timer(.start)) }
      },
      element: Destination.init
    )
  }

  // MARK: - Child Reducers

  struct Destination: ReducerProtocol {
    struct State: Identifiable {
      var id: String
      var timer = TimerExample.State()
    }

    enum Action {
      case push(NavigationStackExample.State.Path)
      case set(NavigationStackExample.State.Path)
      case pop
      case popToRoot
      case shuffle
      case timer(TimerExample.Action)
    }

    var body: some ReducerProtocol<State, Action> {
      Scope(state: \.timer, action: /Action.timer) {
        TimerExample()
      }
    }
  }
}

struct NavigationStackExampleView: View {
  let store: StoreOf<NavigationStackExample>

  var body: some View {
    if #available(iOS 16, *) {
      WithViewStore(store, observe: \.path) { viewStore in
        VStack(spacing: 0) {
          NavigationStack(path: viewStore.binding(
            send: NavigationStackExample.Action.updatePath
          )) {
            Button {
              viewStore.send(.start)
            } label: {
              Text("Start")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .navigationTitle("Root")
            .navigationDestination(
              forEach: store.scope(state: \.stack),
              action: NavigationStackExample.Action.destination,
              destination: DestinationView.init(store:)
            )
          }

          Divider()

          ScrollView(.horizontal, showsIndicators: false) {
            HStack {
              Button {
                viewStore.send(.popToRoot)
              } label: {
                Text("Root")
              }

              ForEach(viewStore.state, id: \.self) { id in
                Text("→")
                Button {
                  viewStore.send(.popTo(id))
                } label: {
                  Text(id)
                }
              }
            }
            .padding()
          }
        }
      }
    } else {
      Text("iOS ≥ 16 required")
    }
  }

  // MARK: - Child Views

  struct DestinationView: View {
    let store: StoreOf<NavigationStackExample.Destination>

    struct ViewState: Equatable {
      init(state: NavigationStackExample.Destination.State) {
        title = state.id
      }

      var title: String
    }

    var body: some View {
      WithViewStore(store, observe: ViewState.init) { viewStore in
        Form {
          Section {
            TimerExampleView(store: store.scope(
              state: \.timer,
              action: NavigationStackExample.Destination.Action.timer
            ))
          } header: {
            Text("Timer")
          }

          Section {
            Button(action: { viewStore.send(.push(["1"])) }) {
              Text("Push 1")
            }

            Button(action: { viewStore.send(.push(["2"])) }) {
              Text("Push 2")
            }

            Button(action: { viewStore.send(.push(["3"])) }) {
              Text("Push 3")
            }

            Button(action: { viewStore.send(.push(["1", "2", "3"])) }) {
              Text("Push 1→2→3")
            }

            Button(action: { viewStore.send(.push(["3", "2", "1"])) }) {
              Text("Push 3→2→1")
            }

            Button(action: { viewStore.send(.set(["1", "2", "3"])) }) {
              Text("Set 1→2→3")
            }

            Button(action: { viewStore.send(.set(["3", "2", "1"])) }) {
              Text("Set 3→2→1")
            }

            Button(action: { viewStore.send(.pop) }) {
              Text("Pop")
            }

            Button(action: { viewStore.send(.popToRoot) }) {
              Text("Pop to root")
            }

            Button(action: { viewStore.send(.shuffle) }) {
              Text("Shuffle")
            }
          } header: {
            Text("Stack navigation")
          }
        }
        .navigationTitle(viewStore.title)
      }
    }
  }
}

struct NavigationStackExample_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStackExampleView(store: Store(
      initialState: NavigationStackExample.State(),
      reducer: NavigationStackExample()
    ))
  }
}
