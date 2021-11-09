import Combine
import ComposableArchitecture
import XCTest
@testable import ComposablePresentation

final class ReducerPresentsKeyPathTests: XCTestCase {
  override func setUp() {
    combinedReducerOtherEffectsCancellationCount = 0
  }

  func testCancelEffectsOnDismiss() {
    var didSubscribeToEffect = 0
    var didCancelEffect = 0

    let store = TestStore(
      initialState: MasterState(),
      reducer: masterReducer,
      environment: MasterEnvironment(
        detail: DetailEnvironment(effect: {
          Empty(completeImmediately: false)
            .handleEvents(
              receiveSubscription: { _ in didSubscribeToEffect += 1 },
              receiveCancel: { didCancelEffect += 1 }
            )
            .eraseToEffect()
        })
      )
    )

    store.send(.presentDetail) {
      $0.detail = DetailState()
    }

    XCTAssertEqual(didSubscribeToEffect, 0)
    XCTAssertEqual(didCancelEffect, 0)
    XCTAssertEqual(combinedReducerOtherEffectsCancellationCount, 0)

    store.send(.detail(.performEffect))

    XCTAssertEqual(didSubscribeToEffect, 1)
    XCTAssertEqual(didCancelEffect, 0)
    XCTAssertEqual(combinedReducerOtherEffectsCancellationCount, 0)

    store.send(.dismissDetail) {
      $0.detail = nil
    }

    XCTAssertEqual(didSubscribeToEffect, 1)
    XCTAssertEqual(didCancelEffect, 1)
    XCTAssertEqual(combinedReducerOtherEffectsCancellationCount, 1)

    store.send(.dismissDetail)

    XCTAssertEqual(didSubscribeToEffect, 1)
    XCTAssertEqual(didCancelEffect, 1)
    XCTAssertEqual(combinedReducerOtherEffectsCancellationCount, 1)
  }
}

// MARK: - Master component

private struct MasterState: Equatable {
  var detail: DetailState?
}

private enum MasterAction: Equatable {
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
