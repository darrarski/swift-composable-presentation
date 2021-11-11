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
  ///   - onRun: A closure invoked when another reducer is run. Defaults to an empty closure.
  ///   - onCancel: A closure invoked when effects produced by another reducer are being cancelled.
  ///       Defaults to an empty closure.
  /// - Returns: A single, combined reducer.
  public func presenting<LocalState, LocalAction, LocalEnvironment>(
    _ localReducer: Reducer<LocalState, LocalAction, LocalEnvironment>,
    breakpointOnNil: Bool = true,
    state toLocalState: WritableKeyPath<State, LocalState?>,
    action toLocalAction: CasePath<Action, LocalAction>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment,
    onRun: @escaping () -> Void = {},
    onCancel: @escaping () -> Void = {}
  ) -> Self {
    combined(
      with: localReducer.optional(breakpointOnNil: breakpointOnNil).pullback(
        state: toLocalState,
        action: toLocalAction,
        environment: toLocalEnvironment
      ),
      shouldRun: { action in
        let shouldRun = toLocalAction.extract(from: action) != nil
        if shouldRun { onRun() }
        return shouldRun
      },
      shouldCancelEffects: { oldState, newState in
        let wasPresented = oldState[keyPath: toLocalState] != nil
        let isDismissed = newState[keyPath: toLocalState] == nil
        let shouldCancel = wasPresented && isDismissed
        if shouldCancel { onCancel() }
        return shouldCancel
      }
    )
  }
}
