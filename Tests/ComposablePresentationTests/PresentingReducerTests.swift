import CasePaths
import Combine
import ComposableArchitecture
import XCTest
@testable import ComposablePresentation

@MainActor
final class PresentingReducerTests: XCTestCase {
  func testPresentingWithKeyPath() async {
    var didPresentChild = 0
    var didRunChildReducer = 0
    let didFireChildEffect = ActorIsolated(0)
    var didDismissChild = 0
    let didCancelChildEffect = ActorIsolated(0)

    struct Parent: ReducerProtocol {
      struct State: Equatable {
        var child: Child.State?
      }

      enum Action: Equatable {
        case presentChild
        case dismissChild
        case child(Child.Action)
      }

      func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .presentChild:
          state.child = Child.State()
          return .none

        case .dismissChild:
          state.child = nil
          return .none

        case .child:
          return .none
        }
      }
    }

    struct Child: ReducerProtocol {
      struct State: Equatable {}

      enum Action: Equatable {
        case performEffect
        case didPerformEffect
      }

      var effect: () -> EffectTask<Void>
      var onReduce: () -> Void

      func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        onReduce()
        switch action {
        case .performEffect:
          return effect()
            .map { _ in .didPerformEffect }

        case .didPerformEffect:
          return .none
        }
      }
    }

    let store = TestStore(
      initialState: Parent.State(),
      reducer: Parent()
        .presenting(
          state: .keyPath(\.child),
          id: .notNil(),
          action: /Parent.Action.child,
          onPresent: .init { _, _ in
            didPresentChild += 1
            return .none
          },
          onDismiss: .init { _, _ in
            didDismissChild += 1
            return .none
          },
          presented: {
            Child(
              effect: {
                EffectTask.run { [didFireChildEffect, didCancelChildEffect] _ in
                  await didFireChildEffect.withValue { $0 += 1 }
                  while !Task.isCancelled {
                    await Task.yield()
                  }
                  await didCancelChildEffect.withValue { $0 += 1 }
                }
              },
              onReduce: { didRunChildReducer += 1 }
            )
          }
        )
    )

    await store.send(.presentChild) {
      $0.child = Child.State()
    }

    XCTAssertEqual(didPresentChild, 1)
    XCTAssertEqual(didRunChildReducer, 0)
    await didFireChildEffect.withValue { XCTAssertEqual($0, 0) }
    XCTAssertEqual(didDismissChild, 0)
    await didCancelChildEffect.withValue { XCTAssertEqual($0, 0) }

    await store.send(.child(.performEffect))

    XCTAssertEqual(didPresentChild, 1)
    XCTAssertEqual(didRunChildReducer, 1)
    await didFireChildEffect.withValue { XCTAssertEqual($0, 1) }
    XCTAssertEqual(didDismissChild, 0)
    await didCancelChildEffect.withValue { XCTAssertEqual($0, 0) }

    await store.send(.dismissChild) {
      $0.child = nil
    }

    XCTAssertEqual(didPresentChild, 1)
    XCTAssertEqual(didRunChildReducer, 1)
    await didFireChildEffect.withValue { XCTAssertEqual($0, 1) }
    XCTAssertEqual(didDismissChild, 1)
    await didCancelChildEffect.withValue { XCTAssertEqual($0, 1) }
  }

  func testPresentingWithCasePath() async {
    var didPresentFirst = 0
    var didRunFirstReducer = 0
    let didFireFirstEffect = ActorIsolated(0)
    var didDismissFirst = 0
    let didCancelFirstEffect = ActorIsolated(0)

    var didPresentSecond = 0
    var didRunSecondReducer = 0
    let didFireSecondEffect = ActorIsolated(0)
    var didDismissSecond = 0
    let didCancelSecondEffect = ActorIsolated(0)

    struct Parent: ReducerProtocol {
      enum State: Equatable {
        case first(First.State)
        case second(Second.State)
      }

      enum Action: Equatable {
        case presentFirst
        case presentSecond
        case first(First.Action)
        case second(Second.Action)
      }

      func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .presentFirst:
          state = .first(First.State())
          return .none

        case .presentSecond:
          state = .second(Second.State())
          return .none

        case .first(_), .second(_):
          return .none
        }
      }
    }

    struct First: ReducerProtocol {
      struct State: Equatable {}

      enum Action: Equatable {
        case performEffect
        case didPerformEffect
      }

      var effect: () -> EffectTask<Void>
      var onReduce: () -> Void

      func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        onReduce()
        switch action {
        case .performEffect:
          return effect().map { _ in .didPerformEffect }

        case .didPerformEffect:
          return .none
        }
      }
    }

    struct Second: ReducerProtocol {
      struct State: Equatable {}

      enum Action: Equatable {
        case performEffect
        case didPerformEffect
      }

      var effect: () -> EffectTask<Void>
      var onReduce: () -> Void

      func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        onReduce()
        switch action {
        case .performEffect:
          return effect().map { _ in .didPerformEffect }

        case .didPerformEffect:
          return .none
        }
      }
    }

    let store = TestStore(
      initialState: Parent.State.first(First.State()),
      reducer: Parent()
        .presenting(
          state: .casePath(/Parent.State.first),
          id: .notNil(),
          action: /Parent.Action.first,
          onPresent: .init { _, _ in
            didPresentFirst += 1
            return .none
          },
          onDismiss: .init { _, _ in
            didDismissFirst += 1
            return .none
          },
          presented: {
            First(
              effect: {
                EffectTask.run { [didFireFirstEffect, didCancelFirstEffect] _ in
                  await didFireFirstEffect.withValue { $0 += 1 }
                  while !Task.isCancelled {
                    await Task.yield()
                  }
                  await didCancelFirstEffect.withValue { $0 += 1 }
                }
              },
              onReduce: {
                didRunFirstReducer += 1
              }
            )
          }
        )
        .presenting(
          state: .casePath(/Parent.State.second),
          id: .notNil(),
          action: /Parent.Action.second,
          onPresent: .init { _, _ in
            didPresentSecond += 1
            return .none
          },
          onDismiss: .init { _, _ in
            didDismissSecond += 1
            return .none
          },
          presented: {
            Second(
              effect: {
                EffectTask.run { [didFireSecondEffect, didCancelSecondEffect] _ in
                  await didFireSecondEffect.withValue { $0 += 1 }
                  while !Task.isCancelled {
                    await Task.yield()
                  }
                  await didCancelSecondEffect.withValue { $0 += 1 }
                }
              },
              onReduce: {
                didRunSecondReducer += 1
              }
            )
          }
        )
    )

    await store.send(.first(.performEffect))

    XCTAssertEqual(didPresentFirst, 0)
    XCTAssertEqual(didRunFirstReducer, 1)
    await didFireFirstEffect.withValue { XCTAssertEqual($0, 1) }
    XCTAssertEqual(didDismissFirst, 0)
    await didCancelFirstEffect.withValue { XCTAssertEqual($0, 0) }

    XCTAssertEqual(didPresentSecond, 0)
    XCTAssertEqual(didRunSecondReducer, 0)
    await didFireSecondEffect.withValue { XCTAssertEqual($0, 0) }
    XCTAssertEqual(didDismissSecond, 0)
    await didCancelSecondEffect.withValue { XCTAssertEqual($0, 0) }

    await store.send(.presentSecond) {
      $0 = .second(Second.State())
    }

    XCTAssertEqual(didPresentFirst, 0)
    XCTAssertEqual(didRunFirstReducer, 1)
    await didFireFirstEffect.withValue { XCTAssertEqual($0, 1) }
    XCTAssertEqual(didDismissFirst, 1)
    await didCancelFirstEffect.withValue { XCTAssertEqual($0, 1) }

    XCTAssertEqual(didPresentSecond, 1)
    XCTAssertEqual(didRunSecondReducer, 0)
    await didFireSecondEffect.withValue { XCTAssertEqual($0, 0) }
    XCTAssertEqual(didDismissSecond, 0)
    await didCancelSecondEffect.withValue { XCTAssertEqual($0, 0) }

    await store.send(.second(.performEffect))

    XCTAssertEqual(didPresentFirst, 0)
    XCTAssertEqual(didRunFirstReducer, 1)
    await didFireFirstEffect.withValue { XCTAssertEqual($0, 1) }
    XCTAssertEqual(didDismissFirst, 1)
    await didCancelFirstEffect.withValue { XCTAssertEqual($0, 1) }

    XCTAssertEqual(didPresentSecond, 1)
    XCTAssertEqual(didRunSecondReducer, 1)
    await didFireSecondEffect.withValue { XCTAssertEqual($0, 1) }
    XCTAssertEqual(didDismissSecond, 0)
    await didCancelSecondEffect.withValue { XCTAssertEqual($0, 0) }

    await store.send(.presentFirst) {
      $0 = .first(First.State())
    }

    XCTAssertEqual(didPresentFirst, 1)
    XCTAssertEqual(didRunFirstReducer, 1)
    await didFireFirstEffect.withValue { XCTAssertEqual($0, 1) }
    XCTAssertEqual(didDismissFirst, 1)
    await didCancelFirstEffect.withValue { XCTAssertEqual($0, 1) }

    XCTAssertEqual(didPresentSecond, 1)
    XCTAssertEqual(didRunSecondReducer, 1)
    await didFireSecondEffect.withValue { XCTAssertEqual($0, 1) }
    XCTAssertEqual(didDismissSecond, 1)
    await didCancelSecondEffect.withValue { XCTAssertEqual($0, 1) }
  }

  func testPresentingWithId() async {
    var didPresentChild = [Child.State.ID]()
    var didRunChildReducer = [Child.State.ID]()
    let didFireChildEffect = ActorIsolated([Child.State.ID]())
    var didDismissChild = [Child.State.ID]()
    let didCancelChildEffect = ActorIsolated([Child.State.ID]())

    struct Parent: ReducerProtocol {
      struct State: Equatable {
        var child: Child.State?
      }

      enum Action: Equatable {
        case presentChild(id: Child.State.ID?)
        case child(Child.Action)
      }

      func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .presentChild(let id):
          state.child = id.map(Child.State.init(id:))
          return .none

        case .child:
          return .none
        }
      }
    }

    struct Child: ReducerProtocol {
      struct State: Equatable {
        typealias ID = Int
        var id: ID
      }

      enum Action: Equatable {
        case performEffect
      }

      var effect: (State.ID) -> EffectPublisher<Action, Never>
      var onReduce: (State.ID) -> Void

      func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        onReduce(state.id)
        switch action {
        case .performEffect:
          return effect(state.id)
        }
      }
    }

    let store = TestStore(
      initialState: Parent.State(),
      reducer: Parent()
        .presenting(
          state: .keyPath(\.child),
          id: .keyPath(\.?.id),
          action: /Parent.Action.child,
          onPresent: .init { _, presentedState in
            didPresentChild.append(presentedState.id)
            return .none
          },
          onDismiss: .init { _, presentedState in
            didDismissChild.append(presentedState.id)
            return .none
          },
          presented: {
            Child(
              effect: { id in
                EffectTask.run { [didFireChildEffect, didCancelChildEffect] _ in
                  await didFireChildEffect.withValue { $0.append(id) }
                  while !Task.isCancelled {
                    await Task.yield()
                  }
                  await didCancelChildEffect.withValue { $0.append(id) }
                }
              },
              onReduce: {
                didRunChildReducer.append($0)
              }
            )
          }
        )
    )

    await store.send(.presentChild(id: 1)) {
      $0.child = Child.State(id: 1)
    }

    XCTAssertEqual(didPresentChild, [1])
    XCTAssertEqual(didRunChildReducer, [])
    await didFireChildEffect.withValue { XCTAssertEqual($0, []) }
    XCTAssertEqual(didDismissChild, [])
    await didCancelChildEffect.withValue { XCTAssertEqual($0, []) }

    await store.send(.child(.performEffect))

    XCTAssertEqual(didPresentChild, [1])
    XCTAssertEqual(didRunChildReducer, [1])
    await didFireChildEffect.withValue { XCTAssertEqual($0, [1]) }
    XCTAssertEqual(didDismissChild, [])
    await didCancelChildEffect.withValue { XCTAssertEqual($0, []) }

    await store.send(.presentChild(id: 2)) {
      $0.child = Child.State(id: 2)
    }

    XCTAssertEqual(didPresentChild, [1, 2])
    XCTAssertEqual(didRunChildReducer, [1])
    await didFireChildEffect.withValue { XCTAssertEqual($0, [1]) }
    XCTAssertEqual(didDismissChild, [1])
    await didCancelChildEffect.withValue { XCTAssertEqual($0, [1]) }

    await store.send(.child(.performEffect))

    XCTAssertEqual(didPresentChild, [1, 2])
    XCTAssertEqual(didRunChildReducer, [1, 2])
    await didFireChildEffect.withValue { XCTAssertEqual($0, [1, 2]) }
    XCTAssertEqual(didDismissChild, [1])
    await didCancelChildEffect.withValue { XCTAssertEqual($0, [1]) }

    await store.send(.presentChild(id: nil)) {
      $0.child = nil
    }

    XCTAssertEqual(didPresentChild, [1, 2])
    XCTAssertEqual(didRunChildReducer, [1, 2])
    await didFireChildEffect.withValue { XCTAssertEqual($0, [1, 2]) }
    XCTAssertEqual(didDismissChild, [1, 2])
    await didCancelChildEffect.withValue { XCTAssertEqual($0, [1, 2]) }
  }
}
