import Combine
import ComposableArchitecture
import XCTest
@testable import ComposablePresentation

final class ReducerPresentingKeyPathTests: XCTestCase {
  func testPresenting() {
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
          state: \.detail,
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
}
