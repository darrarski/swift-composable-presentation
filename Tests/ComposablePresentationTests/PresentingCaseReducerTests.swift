import CasePaths
import Combine
import ComposableArchitecture
import XCTest
@testable import ComposablePresentation

final class PresentingCaseReducerTests: XCTestCase {
  func testPresentingCase() {
    enum TestAction: Equatable {
      case didPresentFirst
      case didFireFirstEffect
      case didDismissFirst
      case didCancelFirstEffect
      case didPresentSecond
      case didFireSecondEffect
      case didDismissSecond
      case didCancelSecondEffect
    }

    struct Main: ReducerProtocol {
      struct State: Equatable {
        enum Destination: Equatable {
          case first(First.State)
          case second(Second.State)
        }

        var destination: Destination?
      }

      enum Action {
        case goto(State.Destination?)
        case first(First.Action)
        case second(Second.Action)
      }

      enum Presentation: Hashable {
        case first
        case second
      }

      func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .goto(let destination):
          state.destination = destination
          return .none

        case .first, .second:
          return .none
        }
      }
    }

    struct First: ReducerProtocol {
      struct State: Equatable {}
      struct Action {}

      var didFireEffect: () -> Void
      var didCancelEffect: () -> Void

      func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        Empty(completeImmediately: false)
          .handleEvents(
            receiveSubscription: { _ in didFireEffect() },
            receiveCancel: { didCancelEffect() }
          )
          .eraseToEffect()
      }
    }

    struct Second: ReducerProtocol {
      struct State: Equatable {}
      struct Action {}

      var didFireEffect: () -> Void
      var didCancelEffect: () -> Void

      func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        Empty(completeImmediately: false)
          .handleEvents(
            receiveSubscription: { _ in didFireEffect() },
            receiveCancel: { didCancelEffect() }
          )
          .eraseToEffect()
      }
    }

    var actions: [TestAction] = []

    let store = TestStore(
      initialState: Main.State(),
      reducer: Main()
        .presenting(
          presentationID: .static(Main.Presentation.first),
          unwrapping: \.destination,
          case: /Main.State.Destination.first,
          id: .notNil(),
          action: /Main.Action.first,
          onPresent: .init { _, _ in
            actions.append(.didPresentFirst)
            return .none
          },
          onDismiss: .init { _, _ in
            actions.append(.didDismissFirst)
            return .none
          },
          presented: {
            First(
              didFireEffect: { actions.append(.didFireFirstEffect) },
              didCancelEffect: { actions.append(.didCancelFirstEffect) }
            )
          }
        )
        .presenting(
          presentationID: .static(Main.Presentation.second),
          unwrapping: \.destination,
          case: /Main.State.Destination.second,
          id: .notNil(),
          action: /Main.Action.second,
          onPresent: .init { _, _ in
            actions.append(.didPresentSecond)
            return .none
          },
          onDismiss: .init { _, _ in
            actions.append(.didDismissSecond)
            return .none
          },
          presented: {
            Second(
              didFireEffect: { actions.append(.didFireSecondEffect) },
              didCancelEffect: { actions.append(.didCancelSecondEffect) }
            )
          }
        )
    )

    actions = []
    store.send(.goto(.first(.init()))) {
      $0.destination = .first(First.State())
    }
    XCTAssertNoDifference(actions, [
      .didPresentFirst,
    ])

    actions = []
    store.send(.first(.init()))
    XCTAssertNoDifference(actions, [
      .didFireFirstEffect,
    ])

    actions = []
    store.send(.goto(.second(.init()))) {
      $0.destination = .second(.init())
    }
    XCTAssertNoDifference(actions, [
      .didDismissFirst,
      .didPresentSecond,
      .didCancelFirstEffect,
    ])

    actions = []
    store.send(.second(.init()))
    XCTAssertNoDifference(actions, [
      .didFireSecondEffect,
    ])

    actions = []
    store.send(.goto(nil)) {
      $0.destination = nil
    }
    XCTAssertNoDifference(actions, [
      .didDismissSecond,
      .didCancelSecondEffect,
    ])
  }
}
