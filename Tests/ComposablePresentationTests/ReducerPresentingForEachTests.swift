import Combine
import ComposableArchitecture
import XCTest
@testable import ComposablePresentation

final class ReducerPresentingForEachTests: XCTestCase {
  func testPresenting() {
    var didPresent = [DetailState.ID]()
    var didRun = [DetailState.ID]()
    var didFireEffect = [DetailState.ID]()
    var didDismiss = [DetailState.ID]()
    var didCancelEffect = [DetailState.ID]()

    struct MasterState: Equatable {
      var details: IdentifiedArrayOf<DetailState>
    }

    enum MasterAction: Equatable {
      case presentDetail(id: Int)
      case dismissDetail(id: Int)
      case detail(id: Int, action: DetailAction)
    }

    struct MasterEnvironment {
      var detail: DetailEnvironment
    }

    let masterReducer = Reducer<MasterState, MasterAction, MasterEnvironment>
    { state, action, env in
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

    struct DetailState: Equatable, Identifiable {
      var id: Int
    }

    enum DetailAction: Equatable {
      case performEffect
      case didPerformEffect
    }

    struct DetailEnvironment {
      var effect: (DetailState.ID) -> Effect<Void, Never>
    }

    let detailReducer = Reducer<DetailState, DetailAction, DetailEnvironment>
    { state, action, env in
      didRun.append(state.id)
      switch action {
      case .performEffect:
        return env.effect(state.id)
          .map { _ in DetailAction.didPerformEffect }
          .eraseToEffect()

      case .didPerformEffect:
        return .none
      }
    }

    let store = TestStore(
      initialState: MasterState(details: []),
      reducer: masterReducer
        .presenting(
          forEach: detailReducer,
          state: \.details,
          action: /MasterAction.detail(id:action:),
          environment: \.detail,
          onPresent: .init { id, _, _ in
            didPresent.append(id)
            return .none
          },
          onDismiss: .init { id, _, _ in
            didDismiss.append(id)
            return .none
          }
        ),
      environment: MasterEnvironment(
        detail: DetailEnvironment(
          effect: { id in
            Empty(completeImmediately: false)
              .handleEvents(
                receiveSubscription: { _ in didFireEffect.append(id) },
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

    XCTAssertEqual(didPresent, [1])
    XCTAssertEqual(didRun, [])
    XCTAssertEqual(didFireEffect, [])
    XCTAssertEqual(didDismiss, [])
    XCTAssertEqual(didCancelEffect, [])

    store.send(.detail(id: 1, action: .performEffect))

    XCTAssertEqual(didPresent, [1])
    XCTAssertEqual(didRun, [1])
    XCTAssertEqual(didFireEffect, [1])
    XCTAssertEqual(didDismiss, [])
    XCTAssertEqual(didCancelEffect, [])

    store.send(.presentDetail(id: 2)) {
      $0.details.append(DetailState(id: 2))
    }

    XCTAssertEqual(didPresent, [1, 2])
    XCTAssertEqual(didRun, [1])
    XCTAssertEqual(didFireEffect, [1])
    XCTAssertEqual(didDismiss, [])
    XCTAssertEqual(didCancelEffect, [])

    store.send(.detail(id: 2, action: .performEffect))

    XCTAssertEqual(didPresent, [1, 2])
    XCTAssertEqual(didRun, [1, 2])
    XCTAssertEqual(didFireEffect, [1, 2])
    XCTAssertEqual(didDismiss, [])
    XCTAssertEqual(didCancelEffect, [])

    store.send(.dismissDetail(id: 1)) {
      $0.details.remove(id: 1)
    }

    XCTAssertEqual(didPresent, [1, 2])
    XCTAssertEqual(didRun, [1, 2])
    XCTAssertEqual(didFireEffect, [1, 2])
    XCTAssertEqual(didDismiss, [1])
    XCTAssertEqual(didCancelEffect, [1])

    store.send(.dismissDetail(id: 2)) {
      $0.details.remove(id: 2)
    }

    XCTAssertEqual(didPresent, [1, 2])
    XCTAssertEqual(didRun, [1, 2])
    XCTAssertEqual(didFireEffect, [1, 2])
    XCTAssertEqual(didDismiss, [1, 2])
    XCTAssertEqual(didCancelEffect, [1, 2])
  }
}
