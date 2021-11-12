import Combine
import ComposableArchitecture
import XCTest
@testable import ComposablePresentation

final class ReducerPresentingForEachTests: XCTestCase {
  func testCancelEffectsOnDismiss() {
    var didRunPresentedReducer: [DetailState.ID] = []
    var didCancelPresentedEffects: [DetailState.ID] = []
    var didSubscribeToEffect: [DetailState.ID] = []
    var didCancelEffect: [DetailState.ID] = []

    let store = TestStore(
      initialState: MasterState(details: []),
      reducer: masterReducer
        .presenting(
          forEach: detailReducer,
          state: \.details,
          action: /MasterAction.detail(id:action:),
          environment: \.detail,
          onRun: { didRunPresentedReducer.append($0) },
          onCancel: { didCancelPresentedEffects.append($0) }
        ),
      environment: MasterEnvironment(
        detail: DetailEnvironment(
          effect: { id in
            Empty(completeImmediately: false)
              .handleEvents(
                receiveSubscription: { _ in didSubscribeToEffect.append(id) },
                receiveCancel: { didCancelEffect.append(id) }
              )
              .eraseToEffect()
          }
        )
      )
    )

    store.send(.presentDetail(id: 1)) {
      $0.details.append(DetailState(id: 1))
    }

    XCTAssertEqual(didRunPresentedReducer, [])
    XCTAssertEqual(didCancelPresentedEffects, [])
    XCTAssertEqual(didSubscribeToEffect, [])
    XCTAssertEqual(didCancelEffect, [])

    store.send(.detail(id: 1, action: .performEffect))

    XCTAssertEqual(didRunPresentedReducer, [1])
    XCTAssertEqual(didCancelPresentedEffects, [])
    XCTAssertEqual(didSubscribeToEffect, [1])
    XCTAssertEqual(didCancelEffect, [])

    store.send(.presentDetail(id: 2)) {
      $0.details.append(DetailState(id: 2))
    }

    XCTAssertEqual(didRunPresentedReducer, [1])
    XCTAssertEqual(didCancelPresentedEffects, [])
    XCTAssertEqual(didSubscribeToEffect, [1])
    XCTAssertEqual(didCancelEffect, [])

    store.send(.detail(id: 2, action: .performEffect))

    XCTAssertEqual(didRunPresentedReducer, [1, 2])
    XCTAssertEqual(didCancelPresentedEffects, [])
    XCTAssertEqual(didSubscribeToEffect, [1, 2])
    XCTAssertEqual(didCancelEffect, [])

    store.send(.dismissDetail(id: 1)) {
      $0.details.remove(id: 1)
    }

    XCTAssertEqual(didRunPresentedReducer, [1, 2])
    XCTAssertEqual(didCancelPresentedEffects, [1])
    XCTAssertEqual(didSubscribeToEffect, [1, 2])
    XCTAssertEqual(didCancelEffect, [1])

    store.send(.dismissDetail(id: 2)) {
      $0.details.remove(id: 2)
    }

    XCTAssertEqual(didRunPresentedReducer, [1, 2])
    XCTAssertEqual(didCancelPresentedEffects, [1, 2])
    XCTAssertEqual(didSubscribeToEffect, [1, 2])
    XCTAssertEqual(didCancelEffect, [1, 2])
  }
}

// MARK: - Master component

private struct MasterState: Equatable {
  var details: IdentifiedArrayOf<DetailState>
}

private enum MasterAction: Equatable {
  case presentDetail(id: Int)
  case dismissDetail(id: Int)
  case detail(id: Int, action: DetailAction)
}

private struct MasterEnvironment {
  var detail: DetailEnvironment
}

private typealias MasterReducer = Reducer<MasterState, MasterAction, MasterEnvironment>

private let masterReducer = MasterReducer { state, action, env in
  switch action {
  case let .presentDetail(id):
    state.details.append(DetailState(id: id))
    return .none

  case let .dismissDetail(id):
    _ = state.details.remove(id: id)
    return .none

  case .detail(_, _):
    return .none
  }
}

// MARK: - Detail component

private struct DetailState: Equatable, Identifiable {
  var id: Int
}

private enum DetailAction: Equatable {
  case performEffect
  case didPerformEffect
}

private struct DetailEnvironment {
  var effect: (DetailState.ID) -> Effect<Void, Never>
}

private typealias DetailReducer = Reducer<DetailState, DetailAction, DetailEnvironment>

private let detailReducer = DetailReducer { state, action, env in
  switch action {
  case .performEffect:
    return env.effect(state.id)
      .map { _ in DetailAction.didPerformEffect }
      .eraseToEffect()

  case .didPerformEffect:
    return .none
  }
}
