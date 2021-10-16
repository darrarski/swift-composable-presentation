import Combine
import ComposableArchitecture
import XCTest
@testable import ComposablePresentation

final class ReducerCombinedTests: XCTestCase {
  var reducer: Reducer<[String], String, Void>!
  var shouldRunReducer: Bool!
  var shouldCancelChildEffect: Bool!
  var mainEffectSubject: PassthroughSubject<String, Never>!
  var childEffectSubject: PassthroughSubject<String, Never>!
  var didCallRunsOnStateAction: [RunsClosureArgs]!
  var didCallCancelEffectsOnState: [[String]]!
  var didCancelMainEffect: Bool!
  var didCancelChildEffect: Bool!

  struct RunsClosureArgs: Equatable {
    var state: [String]
    var action: String
  }

  override func setUp() {
    mainEffectSubject = PassthroughSubject()
    childEffectSubject = PassthroughSubject()
    didCallRunsOnStateAction = []
    didCallCancelEffectsOnState = []
    didCancelMainEffect = false
    didCancelChildEffect = false

    reducer = Reducer { state, action, _ in
      state.append("main-reducer-\(action)")
      return self.mainEffectSubject
        .handleEvents(receiveCancel: { self.didCancelMainEffect = true })
        .map { "main-effect-\($0)" }
        .eraseToEffect()
    }
    .combined(
      with: Reducer { state, action, _ in
        state.append("child-reducer-\(action)")
        return self.childEffectSubject
          .handleEvents(receiveCancel: { self.didCancelChildEffect = true })
          .map { "child-effect-\($0)" }
          .eraseToEffect()
      },
      runs: { state, action in
        self.didCallRunsOnStateAction.append(.init(state: state, action: action))
        return self.shouldRunReducer
      },
      cancelEffects: { state in
        self.didCallCancelEffectsOnState.append(state)
        return self.shouldCancelChildEffect
      }
    )
  }

  override func tearDown() {
    reducer = nil
    shouldRunReducer = nil
    shouldCancelChildEffect = nil
    mainEffectSubject = nil
    childEffectSubject = nil
    didCallRunsOnStateAction = nil
    didCallCancelEffectsOnState = nil
    didCancelMainEffect = nil
    didCancelChildEffect = nil
  }

  func testRuns() {
    let store = TestStore(
      initialState: [],
      reducer: reducer,
      environment: ()
    )

    shouldRunReducer = true
    shouldCancelChildEffect = false

    store.send("1") {
      $0.append(contentsOf: ["child-reducer-1", "main-reducer-1"])
    }

    XCTAssertEqual(didCallRunsOnStateAction.count, 1)
    XCTAssertNoDifference(
      didCallRunsOnStateAction.last,
      .init(
        state: [],
        action: "1"
      )
    )

    mainEffectSubject.send("2")

    XCTAssertEqual(didCallRunsOnStateAction.count, 2)
    XCTAssertNoDifference(
      didCallRunsOnStateAction.last,
      .init(
        state: ["child-reducer-1", "main-reducer-1"],
        action: "main-effect-2"
      )
    )

    store.receive("main-effect-2") {
      $0.append(contentsOf: ["child-reducer-main-effect-2", "main-reducer-main-effect-2"])
    }

    childEffectSubject.send("3")

    XCTAssertEqual(didCallRunsOnStateAction.count, 4)
    XCTAssertNoDifference(
      didCallRunsOnStateAction.last,
      .init(
        state: [
          "child-reducer-1",
          "main-reducer-1",
          "child-reducer-main-effect-2",
          "main-reducer-main-effect-2",
          "child-reducer-child-effect-3",
          "main-reducer-child-effect-3"
        ],
        action: "child-effect-3"
      )
    )

    store.receive("child-effect-3") {
      $0.append(contentsOf: ["child-reducer-child-effect-3", "main-reducer-child-effect-3"])
    }

    store.receive("child-effect-3") {
      $0.append(contentsOf: ["child-reducer-child-effect-3", "main-reducer-child-effect-3"])
    }

    mainEffectSubject.send(completion: .finished)
    childEffectSubject.send(completion: .finished)
  }

  func testNotRuns() {
    let store = TestStore(
      initialState: [],
      reducer: reducer,
      environment: ()
    )

    shouldRunReducer = false
    shouldCancelChildEffect = false

    store.send("1") {
      $0.append(contentsOf: ["main-reducer-1"])
    }

    XCTAssertEqual(didCallRunsOnStateAction.count, 1)
    XCTAssertNoDifference(
      didCallRunsOnStateAction.last,
      .init(
        state: [],
        action: "1"
      )
    )

    mainEffectSubject.send("2")

    XCTAssertEqual(didCallRunsOnStateAction.count, 2)
    XCTAssertNoDifference(
      didCallRunsOnStateAction.last,
      .init(
        state: ["main-reducer-1"],
        action: "main-effect-2"
      )
    )

    store.receive("main-effect-2") {
      $0.append(contentsOf: ["main-reducer-main-effect-2"])
    }

    childEffectSubject.send("3")

    XCTAssertEqual(didCallRunsOnStateAction.count, 2)

    mainEffectSubject.send(completion: .finished)
    childEffectSubject.send(completion: .finished)
  }

  func testCancelChildEffects() {
    let store = TestStore(
      initialState: [],
      reducer: reducer,
      environment: ()
    )

    shouldRunReducer = true
    shouldCancelChildEffect = true

    store.send("1") {
      $0.append(contentsOf: ["child-reducer-1", "main-reducer-1"])
    }

    XCTAssertEqual(didCallCancelEffectsOnState.count, 1)
    XCTAssertEqual(didCallCancelEffectsOnState.last, ["child-reducer-1", "main-reducer-1"])
    XCTAssertFalse(didCancelMainEffect)
    XCTAssertTrue(didCancelChildEffect)

    mainEffectSubject.send("2")

    store.receive("main-effect-2") {
      $0.append(contentsOf: ["child-reducer-main-effect-2", "main-reducer-main-effect-2"])
    }

    childEffectSubject.send("3")

    mainEffectSubject.send(completion: .finished)
  }

  func testNotCancelChildEffects() {
    let store = TestStore(
      initialState: [],
      reducer: reducer,
      environment: ()
    )

    shouldRunReducer = true
    shouldCancelChildEffect = false

    store.send("1") {
      $0.append(contentsOf: ["child-reducer-1", "main-reducer-1"])
    }

    XCTAssertEqual(didCallCancelEffectsOnState.count, 1)
    XCTAssertEqual(didCallCancelEffectsOnState.last, ["child-reducer-1", "main-reducer-1"])
    XCTAssertFalse(didCancelMainEffect)
    XCTAssertFalse(didCancelChildEffect)

    mainEffectSubject.send("2")

    store.receive("main-effect-2") {
      $0.append(contentsOf: ["child-reducer-main-effect-2", "main-reducer-main-effect-2"])
    }

    childEffectSubject.send("3")

    store.receive("child-effect-3") {
      $0.append(contentsOf: ["child-reducer-child-effect-3", "main-reducer-child-effect-3"])
    }

    store.receive("child-effect-3") {
      $0.append(contentsOf: ["child-reducer-child-effect-3", "main-reducer-child-effect-3"])
    }

    mainEffectSubject.send(completion: .finished)
    childEffectSubject.send(completion: .finished)
  }
}
