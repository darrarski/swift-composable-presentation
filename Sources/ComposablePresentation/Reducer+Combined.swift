import ComposableArchitecture

extension Reducer {
  /// Combines the reducer with another reducer that works on the same state, action, and environment.
  ///
  /// - Another reducer is run before the reducer on which the function is invoked.
  /// - All effects returned by the reducers are merged.
  /// - The `cancelEffects` closure is run with a `State` before and after reducing by both reducers.
  /// - If the closure returns `true`, all effects returned by another reducer are canceled.
  ///
  /// Based on [Reducer.presents function](https://github.com/pointfreeco/swift-composable-architecture/blob/9ec4b71e5a84f448dedb063a21673e4696ce135f/Sources/ComposableArchitecture/Reducer.swift#L549-L572) from `iso` branch of `swift-composable-architecture` repository.
  ///
  /// - Parameters:
  ///   - other: Another reducer.
  ///   - shouldRun: Closure used to determine if the other reducer should be run.
  ///       It takes `Action` as a parameter.
  ///   - cancelEffects: Closure used to determine if the effects returned by the another reducer should be cancelled.
  ///       It takes two parameters of type `State`: the state before and after running the reducer.
  /// - Returns: A single, combined reducer.
  public func combined(
    with other: Reducer<State, Action, Environment>,
    run shouldRun: @escaping (Action) -> Bool,
    cancelEffects shouldCancelEffects: @escaping (State, State) -> Bool
  ) -> Self {
    let otherEffectsId = EffectsId()
    return Reducer { state, action, environment in
      let oldState = state
      let otherEffects: Effect<Action, Never>
      if shouldRun(action) {
        otherEffects = other
          .run(&state, action, environment)
          .cancellable(id: otherEffectsId)
      } else {
        otherEffects = .none
      }
      let effects = run(&state, action, environment)
      let newState = state
      let shouldCancelEffects = shouldCancelEffects(oldState, newState)

      return .merge(
        otherEffects,
        effects,
        shouldCancelEffects ? .cancel(id: otherEffectsId) : .none
      )
    }
  }
}

private struct EffectsId: Hashable {
  let id = UUID()
}
