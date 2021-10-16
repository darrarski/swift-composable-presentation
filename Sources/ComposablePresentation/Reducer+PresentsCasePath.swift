import ComposableArchitecture

extension Reducer {
  /// Combines the reducer with another reducer that works on optionally presented `LocalState`.
  ///
  /// - All effects returned by another reducer will be canceled when `LocalState` becomes `nil`.
  ///
  /// - Parameters:
  ///   - localReducer: A reducer that works on `LocalState`, `LocalAction`, `LocalEnvironment`.
  ///   - toLocalState: A case path that can extract/embed `LocalState` from `State`.
  ///   - toLocalAction: A case path that can extract/embed `LocalAction` from `Action`.
  ///   - toLocalEnvironment: A function that transforms `Environment` into `LocalEnvironment`.
  /// - Returns: A single, combined reducer.
  public func presents<LocalState, LocalAction, LocalEnvironment>(
    _ localReducer: Reducer<LocalState, LocalAction, LocalEnvironment>,
    state toLocalState: CasePath<State, LocalState>,
    action toLocalAction: CasePath<Action, LocalAction>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment
  ) -> Self {
    combined(
      with: localReducer.pullback(
        state: toLocalState,
        action: toLocalAction,
        environment: toLocalEnvironment
      ),
      runs: { state, action in
        toLocalAction.extract(from: action) != nil
      },
      cancelEffects: { state in
        toLocalState.extract(from: state) == nil
      }
    )
  }
}
