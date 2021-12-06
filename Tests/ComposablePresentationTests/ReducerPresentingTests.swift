import CasePaths
import Combine
import ComposableArchitecture
import XCTest
@testable import ComposablePresentation

final class ReducerPresentingTests: XCTestCase {
  func testPresentingWithKeyPath() {
    var didPresentDetail = 0
    var didRunDetailReducer = 0
    var didFireDetailEffect = 0
    var didDismissDetail = 0
    var didCancelDetailEffect = 0

    struct MasterState: Equatable {
      var detail: DetailState?
    }

    enum MasterAction: Equatable {
      case presentDetail
      case dismissDetail
      case detail(DetailAction)
    }

    struct MasterEnvironment {
      var detail: DetailEnvironment
    }

    let masterReducer = Reducer<MasterState, MasterAction, MasterEnvironment>
    { state, action, env in
      switch action {
      case .presentDetail:
        state.detail = DetailState()
        return .none

      case .dismissDetail:
        state.detail = nil
        return .none

      case .detail:
        return .none
      }
    }

    struct DetailState: Equatable {}

    enum DetailAction: Equatable {
      case performEffect
      case didPerformEffect
    }

    struct DetailEnvironment {
      var effect: () -> Effect<Void, Never>
    }

    let detailReducer = Reducer<DetailState, DetailAction, DetailEnvironment>
    { state, action, env in
      didRunDetailReducer += 1
      switch action {
      case .performEffect:
        return env.effect()
          .map { _ in DetailAction.didPerformEffect }
          .eraseToEffect()

      case .didPerformEffect:
        return .none
      }
    }

    let store = TestStore(
      initialState: MasterState(),
      reducer: masterReducer
        .presenting(
          detailReducer,
          state: .keyPath(\.detail),
          action: /MasterAction.detail,
          environment: \.detail,
          onPresent: .init { _, _ in
            didPresentDetail += 1
            return .none
          },
          onDismiss: .init { _, _ in
            didDismissDetail += 1
            return .none
          }
        ),
      environment: MasterEnvironment(
        detail: DetailEnvironment(effect: {
          Empty(completeImmediately: false)
            .handleEvents(
              receiveSubscription: { _ in didFireDetailEffect += 1 },
              receiveCancel: { didCancelDetailEffect += 1 }
            )
            .eraseToEffect()
        })
      )
    )

    store.send(.presentDetail) {
      $0.detail = DetailState()
    }

    XCTAssertEqual(didPresentDetail, 1)
    XCTAssertEqual(didRunDetailReducer, 0)
    XCTAssertEqual(didFireDetailEffect, 0)
    XCTAssertEqual(didDismissDetail, 0)
    XCTAssertEqual(didCancelDetailEffect, 0)

    store.send(.detail(.performEffect))

    XCTAssertEqual(didPresentDetail, 1)
    XCTAssertEqual(didRunDetailReducer, 1)
    XCTAssertEqual(didFireDetailEffect, 1)
    XCTAssertEqual(didDismissDetail, 0)
    XCTAssertEqual(didCancelDetailEffect, 0)

    store.send(.dismissDetail) {
      $0.detail = nil
    }

    XCTAssertEqual(didPresentDetail, 1)
    XCTAssertEqual(didRunDetailReducer, 1)
    XCTAssertEqual(didFireDetailEffect, 1)
    XCTAssertEqual(didDismissDetail, 1)
    XCTAssertEqual(didCancelDetailEffect, 1)
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

    enum MasterState: Equatable {
      case first(FirstState)
      case second(SecondState)
    }

    enum MasterAction: Equatable {
      case presentFirst
      case presentSecond
      case first(FirstAction)
      case second(SecondAction)
    }

    struct MasterEnvironment {
      var first: FirstEnvironment
      var second: SecondEnvironment
    }

    let masterReducer = Reducer<MasterState, MasterAction, MasterEnvironment>
    { state, action, env in
      switch action {
      case .presentFirst:
        state = .first(FirstState())
        return .none

      case .presentSecond:
        state = .second(SecondState())
        return .none

      case .first(_), .second(_):
        return .none
      }
    }

    struct FirstState: Equatable {}

    enum FirstAction: Equatable {
      case performEffect
      case didPerformEffect
    }

    struct FirstEnvironment {
      var effect: () -> Effect<Void, Never>
    }

    let firstReducer = Reducer<FirstState, FirstAction, FirstEnvironment>
    { state, action, env in
      didRunFirstReducer += 1
      switch action {
      case .performEffect:
        return env.effect()
          .map { _ in FirstAction.didPerformEffect }
          .eraseToEffect()

      case .didPerformEffect:
        return .none
      }
    }

    struct SecondState: Equatable {}

    enum SecondAction: Equatable {
      case performEffect
      case didPerformEffect
    }

    struct SecondEnvironment {
      var effect: () -> Effect<Void, Never>
    }

    let secondReducer = Reducer<SecondState, SecondAction, SecondEnvironment>
    { state, action, env in
      didRunSecondReducer += 1
      switch action {
      case .performEffect:
        return env.effect()
          .map { _ in SecondAction.didPerformEffect }
          .eraseToEffect()

      case .didPerformEffect:
        return .none
      }
    }

    let store = TestStore(
      initialState: MasterState.first(FirstState()),
      reducer: masterReducer
        .presenting(
          firstReducer,
          state: .casePath(/MasterState.first),
          action: /MasterAction.first,
          environment: \.first,
          onPresent: .init { _, _ in
            didPresentFirst += 1
            return .none
          },
          onDismiss: .init { _, _ in
            didDismissFirst += 1
            return .none
          }
        )
        .presenting(
          secondReducer,
          state: .casePath(/MasterState.second),
          action: /MasterAction.second,
          environment: \.second,
          onPresent: .init { _, _ in
            didPresentSecond += 1
            return .none
          },
          onDismiss: .init { _, _ in
            didDismissSecond += 1
            return .none
          }
        ),
      environment: MasterEnvironment(
        first: FirstEnvironment(effect: {
          Empty(completeImmediately: false)
            .handleEvents(
              receiveSubscription: { _ in didFireFirstEffect += 1 },
              receiveCancel: { didCancelFirstEffect += 1 }
            )
            .eraseToEffect()
        }),
        second: SecondEnvironment(effect: {
          Empty(completeImmediately: false)
            .handleEvents(
              receiveSubscription: { _ in didFireSecondEffect += 1 },
              receiveCancel: { didCancelSecondEffect += 1 }
            )
            .eraseToEffect()
        })
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
      $0 = .second(SecondState())
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
      $0 = .first(FirstState())
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
}
