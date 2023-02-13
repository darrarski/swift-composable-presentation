import CasePaths
import Combine
import ComposableArchitecture
import XCTest
@testable import ComposablePresentation

final class PresentingReducerTests: XCTestCase {
  func testPresentingWithKeyPath() {
    var didPresentChild = 0
    var didRunChildReducer = 0
    var didFireChildEffect = 0
    var didDismissChild = 0
    var didCancelChildEffect = 0

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
            .eraseToEffect()

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
                Empty(completeImmediately: false)
                  .handleEvents(
                    receiveSubscription: { _ in didFireChildEffect += 1 },
                    receiveCancel: { didCancelChildEffect += 1 }
                  )
                  .eraseToEffect()
              },
              onReduce: { didRunChildReducer += 1 }
            )
          }
        )
    )

    store.send(.presentChild) {
      $0.child = Child.State()
    }

    XCTAssertEqual(didPresentChild, 1)
    XCTAssertEqual(didRunChildReducer, 0)
    XCTAssertEqual(didFireChildEffect, 0)
    XCTAssertEqual(didDismissChild, 0)
    XCTAssertEqual(didCancelChildEffect, 0)

    store.send(.child(.performEffect))

    XCTAssertEqual(didPresentChild, 1)
    XCTAssertEqual(didRunChildReducer, 1)
    XCTAssertEqual(didFireChildEffect, 1)
    XCTAssertEqual(didDismissChild, 0)
    XCTAssertEqual(didCancelChildEffect, 0)

    store.send(.dismissChild) {
      $0.child = nil
    }

    XCTAssertEqual(didPresentChild, 1)
    XCTAssertEqual(didRunChildReducer, 1)
    XCTAssertEqual(didFireChildEffect, 1)
    XCTAssertEqual(didDismissChild, 1)
    XCTAssertEqual(didCancelChildEffect, 1)
  }

  func testPresentingWithCasePath() {
    var didPresentFirst = 0
    var didRunFirstReducer = 0
    var didFireFirstEffect = 0
    var didDismissFirst = 0
    var didCancelFirstEffect = 0

    var didPresentSecond = 0
    var didRunSecondReducer = 0
    var didFireSecondEffect = 0
    var didDismissSecond = 0
    var didCancelSecondEffect = 0

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
          return effect()
            .map { _ in .didPerformEffect }
            .eraseToEffect()

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
          return effect()
            .map { _ in .didPerformEffect }
            .eraseToEffect()

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
                Empty(completeImmediately: false)
                  .handleEvents(
                    receiveSubscription: { _ in didFireFirstEffect += 1 },
                    receiveCancel: { didCancelFirstEffect += 1 }
                  )
                  .eraseToEffect()
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
                Empty(completeImmediately: false)
                  .handleEvents(
                    receiveSubscription: { _ in didFireSecondEffect += 1 },
                    receiveCancel: { didCancelSecondEffect += 1 }
                  )
                  .eraseToEffect()
              },
              onReduce: {
                didRunSecondReducer += 1
              }
            )
          }
        )
    )

    store.send(.first(.performEffect))

    XCTAssertEqual(didPresentFirst, 0)
    XCTAssertEqual(didRunFirstReducer, 1)
    XCTAssertEqual(didFireFirstEffect, 1)
    XCTAssertEqual(didDismissFirst, 0)
    XCTAssertEqual(didCancelFirstEffect, 0)

    XCTAssertEqual(didPresentSecond, 0)
    XCTAssertEqual(didRunSecondReducer, 0)
    XCTAssertEqual(didFireSecondEffect, 0)
    XCTAssertEqual(didDismissSecond, 0)
    XCTAssertEqual(didCancelSecondEffect, 0)

    store.send(.presentSecond) {
      $0 = .second(Second.State())
    }

    XCTAssertEqual(didPresentFirst, 0)
    XCTAssertEqual(didRunFirstReducer, 1)
    XCTAssertEqual(didFireFirstEffect, 1)
    XCTAssertEqual(didDismissFirst, 1)
    XCTAssertEqual(didCancelFirstEffect, 1)

    XCTAssertEqual(didPresentSecond, 1)
    XCTAssertEqual(didRunSecondReducer, 0)
    XCTAssertEqual(didFireSecondEffect, 0)
    XCTAssertEqual(didDismissSecond, 0)
    XCTAssertEqual(didCancelSecondEffect, 0)

    store.send(.second(.performEffect))

    XCTAssertEqual(didPresentFirst, 0)
    XCTAssertEqual(didRunFirstReducer, 1)
    XCTAssertEqual(didFireFirstEffect, 1)
    XCTAssertEqual(didDismissFirst, 1)
    XCTAssertEqual(didCancelFirstEffect, 1)

    XCTAssertEqual(didPresentSecond, 1)
    XCTAssertEqual(didRunSecondReducer, 1)
    XCTAssertEqual(didFireSecondEffect, 1)
    XCTAssertEqual(didDismissSecond, 0)
    XCTAssertEqual(didCancelSecondEffect, 0)

    store.send(.presentFirst) {
      $0 = .first(First.State())
    }

    XCTAssertEqual(didPresentFirst, 1)
    XCTAssertEqual(didRunFirstReducer, 1)
    XCTAssertEqual(didFireFirstEffect, 1)
    XCTAssertEqual(didDismissFirst, 1)
    XCTAssertEqual(didCancelFirstEffect, 1)

    XCTAssertEqual(didPresentSecond, 1)
    XCTAssertEqual(didRunSecondReducer, 1)
    XCTAssertEqual(didFireSecondEffect, 1)
    XCTAssertEqual(didDismissSecond, 1)
    XCTAssertEqual(didCancelSecondEffect, 1)
  }

  func testPresentingWithId() {
    var didPresentChild = [Child.State.ID]()
    var didRunChildReducer = [Child.State.ID]()
    var didFireChildEffect = [Child.State.ID]()
    var didDismissChild = [Child.State.ID]()
    var didCancelChildEffect = [Child.State.ID]()

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

      var effect: (State.ID) -> EffectTask<Never>
      var onReduce: (State.ID) -> Void

      func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        onReduce(state.id)
        switch action {
        case .performEffect:
          return effect(state.id)
            .fireAndForget()
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
                Empty(completeImmediately: false)
                  .handleEvents(
                    receiveSubscription: { _ in didFireChildEffect.append(id) },
                    receiveCancel: { didCancelChildEffect.append(id) }
                  )
                  .eraseToEffect()
              },
              onReduce: {
                didRunChildReducer.append($0)
              }
            )
          }
        )
    )

    store.send(.presentChild(id: 1)) {
      $0.child = Child.State(id: 1)
    }

    XCTAssertEqual(didPresentChild, [1])
    XCTAssertEqual(didRunChildReducer, [])
    XCTAssertEqual(didFireChildEffect, [])
    XCTAssertEqual(didDismissChild, [])
    XCTAssertEqual(didCancelChildEffect, [])

    store.send(.child(.performEffect))

    XCTAssertEqual(didPresentChild, [1])
    XCTAssertEqual(didRunChildReducer, [1])
    XCTAssertEqual(didFireChildEffect, [1])
    XCTAssertEqual(didDismissChild, [])
    XCTAssertEqual(didCancelChildEffect, [])

    store.send(.presentChild(id: 2)) {
      $0.child = Child.State(id: 2)
    }

    XCTAssertEqual(didPresentChild, [1, 2])
    XCTAssertEqual(didRunChildReducer, [1])
    XCTAssertEqual(didFireChildEffect, [1])
    XCTAssertEqual(didDismissChild, [1])
    XCTAssertEqual(didCancelChildEffect, [1])

    store.send(.child(.performEffect))

    XCTAssertEqual(didPresentChild, [1, 2])
    XCTAssertEqual(didRunChildReducer, [1, 2])
    XCTAssertEqual(didFireChildEffect, [1, 2])
    XCTAssertEqual(didDismissChild, [1])
    XCTAssertEqual(didCancelChildEffect, [1])

    store.send(.presentChild(id: nil)) {
      $0.child = nil
    }

    XCTAssertEqual(didPresentChild, [1, 2])
    XCTAssertEqual(didRunChildReducer, [1, 2])
    XCTAssertEqual(didFireChildEffect, [1, 2])
    XCTAssertEqual(didDismissChild, [1, 2])
    XCTAssertEqual(didCancelChildEffect, [1, 2])
  }
}
