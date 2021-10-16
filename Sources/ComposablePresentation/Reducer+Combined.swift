import ComposableArchitecture

extension Reducer {
  /// Combines the reducer with another reducer that works on the same state, action, and environment.
  ///
  /// - Another reducer is run before the reducer on which the function is invoked.
  /// - All effects returned by the reducers are merged.
  /// - The `runs` closure is run with a `State` and `Action` *before* being reducer by either reducer.
  /// - The `cancelEffects` closure is run with a `State` reduced by both reducers.
  /// - If the closure returns `true`, all effects returned by another reducer are canceled.
  ///
  /// Based on [Reducer.presents function](https://github.com/pointfreeco/swift-composable-architecture/blob/9ec4b71e5a84f448dedb063a21673e4696ce135f/Sources/ComposableArchitecture/Reducer.swift#L549-L572) from `iso` branch of `swift-composable-architecture` repository.
  ///
  /// - Parameters:
  ///   - other: Another reducer.
  ///   - runs: Closure used to determine if the another reducer should be run.
  ///   - cancelEffects: Closure used to determine if the effects returned by the another reducer should be cancelled.
  /// - Returns: A single, combined reducer.
  public func combined(
    with other: Reducer<State, Action, Environment>,
    runs: @escaping (State, Action) -> Bool,
    cancelEffects: @escaping (State) -> Bool
  ) -> Self {
    let otherEffectsId = EffectsId()
    return Reducer { state, action, environment in
      var effects: [Effect<Action, Never>] = []

      let shouldRunOtherReducer = runs(state, action)
      if shouldRunOtherReducer {
        effects.append(
          other
            .run(&state, action, environment)
            .cancellable(id: otherEffectsId)
        )
      }

      effects.append(run(&state, action, environment))

      let shouldCancelOtherEffects = cancelEffects(state)
      if shouldCancelOtherEffects {
        effects.append(.cancel(id: otherEffectsId))
      }

      return .merge(effects)
    }
  }
}

private struct EffectsId: Hashable {
  let id = UUID()
}
