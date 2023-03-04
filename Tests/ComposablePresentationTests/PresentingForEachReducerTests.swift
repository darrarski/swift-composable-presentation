import Combine
import ComposableArchitecture
import XCTest
@testable import ComposablePresentation

@MainActor
final class PresentingForEachReducerTests: XCTestCase {
  func testPresentingWithIdentifiedArray() async {
    var didPresent = [Element.State.ID]()
    var didRun = [Element.State.ID]()
    let didFireEffect = ActorIsolated([Element.State.ID]())
    var didDismiss = [Element.State.ID]()
    let didCancelEffect = ActorIsolated([Element.State.ID]())

    struct Parent: Reducer {
      struct State: Equatable {
        var elements: IdentifiedArrayOf<Element.State>
      }

      enum Action: Equatable {
        case addElement(id: Int)
        case removeElement(id: Int)
        case element(id: Int, action: Element.Action)
      }

      func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .addElement(let id):
          state.elements.append(Element.State(id: id))
          return .none

        case .removeElement(let id):
          _ = state.elements.remove(id: id)
          return .none

        case .element(_, _):
          return .none
        }
      }
    }

    struct Element: Reducer {
      struct State: Equatable, Identifiable {
        var id: Int
      }

      enum Action: Equatable {
        case performEffect
        case didPerformEffect
      }

      var effect: (State.ID) -> Effect<Void>
      var onReduce: (State.ID) -> Void

      func reduce(into state: inout State, action: Action) -> Effect<Action> {
        onReduce(state.id)
        switch action {
        case .performEffect:
          return effect(state.id).map { _ in .didPerformEffect }

        case .didPerformEffect:
          return .none
        }
      }
    }

    let store = TestStore(
      initialState: Parent.State(elements: []),
      reducer: Parent()
        .presentingForEach(
          state: \.elements,
          action: /Parent.Action.element(id:action:),
          onPresent: .init { id, _ in
            didPresent.append(id)
            return .none
          },
          onDismiss: .init { id, _ in
            didDismiss.append(id)
            return .none
          },
          element: {
            Element(
              effect: { id in
                EffectTask.run { [didFireEffect, didCancelEffect] _ in
                  await didFireEffect.withValue { $0.append(id) }
                  while !Task.isCancelled {
                    await Task.yield()
                  }
                  await didCancelEffect.withValue { $0.append(id) }
                }
              },
              onReduce: { id in
                didRun.append(id)
              }
            )
          }
        )
    )

    await store.send(.addElement(id: 1)) {
      $0.elements.append(Element.State(id: 1))
    }

    XCTAssertEqual(didPresent, [1])
    XCTAssertEqual(didRun, [])
    await didFireEffect.withValue { XCTAssertEqual($0, []) }
    XCTAssertEqual(didDismiss, [])
    await didCancelEffect.withValue { XCTAssertEqual($0, []) }

    await store.send(.element(id: 1, action: .performEffect))

    XCTAssertEqual(didPresent, [1])
    XCTAssertEqual(didRun, [1])
    await didFireEffect.withValue { XCTAssertEqual($0, [1]) }
    XCTAssertEqual(didDismiss, [])
    await didCancelEffect.withValue { XCTAssertEqual($0, []) }

    await store.send(.addElement(id: 2)) {
      $0.elements.append(Element.State(id: 2))
    }

    XCTAssertEqual(didPresent, [1, 2])
    XCTAssertEqual(didRun, [1])
    await didFireEffect.withValue { XCTAssertEqual($0, [1]) }
    XCTAssertEqual(didDismiss, [])
    await didCancelEffect.withValue { XCTAssertEqual($0, []) }

    await store.send(.element(id: 2, action: .performEffect))

    XCTAssertEqual(didPresent, [1, 2])
    XCTAssertEqual(didRun, [1, 2])
    await didFireEffect.withValue { XCTAssertEqual($0, [1, 2]) }
    XCTAssertEqual(didDismiss, [])
    await didCancelEffect.withValue { XCTAssertEqual($0, []) }

    await store.send(.removeElement(id: 1)) {
      $0.elements.remove(id: 1)
    }

    XCTAssertEqual(didPresent, [1, 2])
    XCTAssertEqual(didRun, [1, 2])
    await didFireEffect.withValue { XCTAssertEqual($0, [1, 2]) }
    XCTAssertEqual(didDismiss, [1])
    await didCancelEffect.withValue { XCTAssertEqual($0, [1]) }

    await store.send(.removeElement(id: 2)) {
      $0.elements.remove(id: 2)
    }

    XCTAssertEqual(didPresent, [1, 2])
    XCTAssertEqual(didRun, [1, 2])
    await didFireEffect.withValue { XCTAssertEqual($0, [1, 2]) }
    XCTAssertEqual(didDismiss, [1, 2])
    await didCancelEffect.withValue { XCTAssertEqual($0, [1, 2]) }
  }
}
