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
    case push(State.Path.Element)
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

      case .push(let id):
        state.stack.append(.init(id: id))
        return .none

      case .destination(let id, .push(let newId)):
        state.stack.append(.init(id: "\(id).\(newId)"))
        return .none

      case .destination(_, .pop):
        _ = state.stack.popLast()
        return .none

      case .destination(_, .popToRoot):
        state.stack.removeAll()
        return .none

      case .destination(_, _):
        return .none
      }
    }
    .presentingForEach(
      state: \.stack,
      action: /Action.destination,
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
      case push(NavigationStackExample.State.Path.Element)
      case pop
      case popToRoot
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
        NavigationStack(path: viewStore.binding(
          send: NavigationStackExample.Action.updatePath
        )) {
          VStack {
            Button(action: { viewStore.send(.push("1")) }) {
              Text("Push 1")
            }

            Button(action: { viewStore.send(.push("2")) }) {
              Text("Push 2")
            }

            Button(action: { viewStore.send(.push("3")) }) {
              Text("Push 3")
            }
          }
          .buttonStyle(.borderedProminent)
          .navigationTitle("Root")
          .navigationDestination(for: NavigationStackExample.State.Path.Element.self) { id in
            IfLetStore(
              store.scope(
                state: { $0.stack[id: id] },
                action: { NavigationStackExample.Action.destination(id, $0) }
              ),
              then: DestinationView.init(store:)
            )
          }
        }
      }
    } else {
      Text("iOS ≥ 16 required")
    }
  }

  // MARK: - Child Views

  @available(iOS 16, *)
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
        VStack {
          TimerExampleView(store: store.scope(
            state: \.timer,
            action: NavigationStackExample.Destination.Action.timer
          ))

          Button(action: { viewStore.send(.push("1")) }) {
            Text("Push 1")
          }

          Button(action: { viewStore.send(.push("2")) }) {
            Text("Push 2")
          }

          Button(action: { viewStore.send(.push("3")) }) {
            Text("Push 3")
          }

          Button(action: { viewStore.send(.pop) }) {
            Text("Pop")
          }

          Button(action: { viewStore.send(.popToRoot) }) {
            Text("Pop to root")
          }
        }
        .buttonStyle(.borderedProminent)
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
