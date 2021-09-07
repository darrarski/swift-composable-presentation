import CasePaths
import Combine
import ComposableArchitecture
import XCTest
@testable import ComposablePresentation

final class ReducerPresentsCasePathTests: XCTestCase {
  func testCancelEffectsOnDismiss() {
    var didSubscribeToFirstEffect = false
    var didCancelFirstEffect = false
    var didSubscribeToSecondEffect = false
    var didCancelSecondEffect = false

    let store = TestStore(
      initialState: MasterState.first(FirstDetailState()),
      reducer: masterReducer,
      environment: MasterEnvironment(
        firstDetail: FirstDetailEnvironment(effect: {
          Empty(completeImmediately: false)
            .handleEvents(
              receiveSubscription: { _ in didSubscribeToFirstEffect = true },
              receiveCancel: { didCancelFirstEffect = true }
            )
            .eraseToEffect()
        }),
        secondDetail: SecondDetailEnvironment(effect: {
          Empty(completeImmediately: false)
            .handleEvents(
              receiveSubscription: { _ in didSubscribeToSecondEffect = true },
              receiveCancel: { didCancelSecondEffect = true }
            )
            .eraseToEffect()
        })
      )
    )

    store.send(.first(.performEffect))

    XCTAssertTrue(didSubscribeToFirstEffect)

    store.send(.presentSecondDetail) {
      $0 = .second(SecondDetailState())
    }

    XCTAssertTrue(didCancelFirstEffect)

    store.send(.second(.performEffect))

    XCTAssertTrue(didSubscribeToSecondEffect)

    store.send(.presentFirstDetail) {
      $0 = .first(FirstDetailState())
    }

    XCTAssertTrue(didCancelSecondEffect)
  }
}

// MARK: - Master component

private enum MasterState: Equatable {
  case first(FirstDetailState)
  case second(SecondDetailState)
}

private enum MasterAction: Equatable {
  case presentFirstDetail
  case presentSecondDetail
  case first(FirstDetailAction)
  case second(SecondDetailAction)
}

private struct MasterEnvironment {
  var firstDetail: FirstDetailEnvironment
  var secondDetail: SecondDetailEnvironment
}

private let masterReducer = Reducer<MasterState, MasterAction, MasterEnvironment>
{ state, action, env in
  switch action {
  case .presentFirstDetail:
    state = .first(FirstDetailState())
    return .none

  case .presentSecondDetail:
    state = .second(SecondDetailState())
    return .none

  case .first(_), .second(_):
    return .none
  }
}
.presents(
  firstDetailReducer,
  state: /MasterState.first,
  action: /MasterAction.first,
  environment: \.firstDetail
)
.presents(
  secondDetailReducer,
  state: /MasterState.second,
  action: /MasterAction.second,
  environment: \.secondDetail
)

// MARK: - FirstDetail component

private struct FirstDetailState: Equatable {}

private enum FirstDetailAction: Equatable {
  case performEffect
  case didPerformEffect
}

private struct FirstDetailEnvironment {
  var effect: () -> Effect<Void, Never>
}

private let firstDetailReducer = Reducer<FirstDetailState, FirstDetailAction, FirstDetailEnvironment>
{ state, action, env in
  switch action {
  case .performEffect:
    return env.effect()
      .map { _ in FirstDetailAction.didPerformEffect }
      .eraseToEffect()

  case .didPerformEffect:
    return .none
  }
}

// MARK: - SecondDetail component

private struct SecondDetailState: Equatable {}

private enum SecondDetailAction: Equatable {
  case performEffect
  case didPerformEffect
}

private struct SecondDetailEnvironment {
  var effect: () -> Effect<Void, Never>
}

private let secondDetailReducer = Reducer<SecondDetailState, SecondDetailAction, SecondDetailEnvironment>
{ state, action, env in
  switch action {
  case .performEffect:
    return env.effect()
      .map { _ in SecondDetailAction.didPerformEffect }
      .eraseToEffect()

  case .didPerformEffect:
    return .none
  }
}
