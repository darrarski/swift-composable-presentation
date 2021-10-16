import Combine
import ComposableArchitecture
import XCTest
@testable import ComposablePresentation

final class ReducerPresentsKeyPathTests: XCTestCase {
  func testCancelEffectsOnDismiss() {
    var didSubscribeToEffect = false
    var didCancelEffect = false

    let store = TestStore(
      initialState: MasterState(),
      reducer: masterReducer,
      environment: MasterEnvironment(
        detail: DetailEnvironment(effect: {
          Empty(completeImmediately: false)
            .handleEvents(
              receiveSubscription: { _ in didSubscribeToEffect = true },
              receiveCancel: { didCancelEffect = true }
            )
            .eraseToEffect()
        })
      )
    )

    presentsKeyPathCancelCounter = 0

    store.send(.noop)

    XCTAssertEqual(presentsKeyPathCancelCounter, 1,
                   "effects are cancelled before state ever existed")

    store.send(.presentDetail) {
      $0.detail = DetailState()
    }

    store.send(.detail(.performEffect))

    XCTAssertEqual(presentsKeyPathCancelCounter, 1)
    XCTAssertTrue(didSubscribeToEffect)

    store.send(.dismissDetail) {
      $0.detail = nil
    }

    XCTAssertEqual(presentsKeyPathCancelCounter, 2)
    XCTAssertTrue(didCancelEffect)

    store.send(.noop)

    XCTAssertEqual(presentsKeyPathCancelCounter, 3,
                   "effects are cancelled every time")
  }
}

// MARK: - Master component

private struct MasterState: Equatable {
  var detail: DetailState?
}

private enum MasterAction: Equatable {
  case noop
  case presentDetail
  case dismissDetail
  case detail(DetailAction)
}

private struct MasterEnvironment {
  var detail: DetailEnvironment
}

private typealias MasterReducer = Reducer<MasterState, MasterAction, MasterEnvironment>

private let masterReducer = MasterReducer { state, action, env in
  switch action {
  case .noop:
    return .none
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
.presents(
  detailReducer,
  state: \.detail,
  action: /MasterAction.detail,
  environment: \.detail
)

// MARK: - Detail component

private struct DetailState: Equatable {}

private enum DetailAction: Equatable {
  case performEffect
  case didPerformEffect
}

private struct DetailEnvironment {
  var effect: () -> Effect<Void, Never>
}

private typealias DetailReducer = Reducer<DetailState, DetailAction, DetailEnvironment>

private let detailReducer = DetailReducer { state, action, env in
  switch action {
  case .performEffect:
    return env.effect()
      .map { _ in DetailAction.didPerformEffect }
      .eraseToEffect()

  case .didPerformEffect:
    return .none
  }
}
