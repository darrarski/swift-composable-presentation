import ComposableArchitecture

extension Reducer {
  /// Combines the reducer with another reducer that works on optionally presented `LocalState`.
  ///
  /// - All effects returned by another reducer will be canceled when `LocalState` becomes `nil`.
  ///
  /// - Parameters:
  ///   - localReducer: A reducer that works on `LocalState`, `LocalAction`, `LocalEnvironment`.
  ///   - breakpointOnNil: If `true`, raises `SIGTRAP` signal when an action is sent to the reducer
  ///     but state is `nil`. This is generally considered a logic error, as a child reducer cannot
  ///     process a child action for unavailable child state (defaults to `true`).
  ///   - toLocalState: A key path that can get/set `LocalState` inside `State`.
  ///   - toLocalAction: A case path that can extract/embed `LocalAction` from `Action`.
  ///   - toLocalEnvironment: A function that transforms `Environment` into `LocalEnvironment`.
  /// - Returns: A single, combined reducer.
  public func presents<LocalState, LocalAction, LocalEnvironment>(
    _ localReducer: Reducer<LocalState, LocalAction, LocalEnvironment>,
    breakpointOnNil: Bool = true,
    state toLocalState: WritableKeyPath<State, LocalState?>,
    action toLocalAction: CasePath<Action, LocalAction>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment
  ) -> Self {
    combined(
      with: localReducer.optional(breakpointOnNil: breakpointOnNil).pullback(
        state: toLocalState,
        action: toLocalAction,
        environment: toLocalEnvironment
      ),
      runs: { state, action in
          true
      },
      cancelEffects: { state in
        state[keyPath: toLocalState] == nil
      }
    )
  }
}
