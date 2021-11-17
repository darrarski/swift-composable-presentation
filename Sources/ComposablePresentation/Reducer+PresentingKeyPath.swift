import ComposableArchitecture

extension Reducer {
  /// Combines the reducer with another reducer that works on optionally presented `LocalState`.
  ///
  /// - All effects returned by another reducer will be canceled when `LocalState` becomes `nil`.
  ///
  /// - Parameters:
  ///   - localReducer: A reducer that works on `LocalState`, `LocalAction`, `LocalEnvironment`.
  ///   - toLocalState: A key path that can get/set `LocalState` inside `State`.
  ///   - toLocalAction: A case path that can extract/embed `LocalAction` from `Action`.
  ///   - toLocalEnvironment: A function that transforms `Environment` into `LocalEnvironment`.
  ///   - breakpointOnNil: If `true`, raises `SIGTRAP` signal when an action is sent to the reducer
  ///       but state is `nil`. This is generally considered a logic error, as a child reducer cannot
  ///       process a child action for unavailable child state. Default value is `true`.
  ///   - onRun: A closure invoked when another reducer is run. Defaults to an empty closure.
  ///   - onCancel: A closure invoked when effects produced by another reducer are being cancelled.
  ///       Defaults to an empty closure.
  /// - Returns: A single, combined reducer.
  public func presenting<LocalState, LocalAction, LocalEnvironment>(
    _ localReducer: Reducer<LocalState, LocalAction, LocalEnvironment>,
    state toLocalState: WritableKeyPath<State, LocalState?>,
    action toLocalAction: CasePath<Action, LocalAction>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment,
    breakpointOnNil: Bool = true,
    onRun: @escaping () -> Void = {},
    onCancel: @escaping () -> Void = {},
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Self {
    let localEffectsId = EffectsId()

    let shouldRun: (Action) -> Bool = { action in
      let shouldRun = toLocalAction.extract(from: action) != nil
      if shouldRun { onRun() }
      return shouldRun
    }

    let shouldCancelEffects: (State, State) -> Bool = { oldState, newState in
      let wasPresented = oldState[keyPath: toLocalState] != nil
      let isDismissed = newState[keyPath: toLocalState] == nil
      let shouldCancel = wasPresented && isDismissed
      if shouldCancel { onCancel() }
      return shouldCancel
    }

    return Reducer { state, action, environment in
      let oldState = state
      let localEffects: Effect<Action, Never>
      if shouldRun(action) {
        localEffects = localReducer
          .optional(
            breakpointOnNil: breakpointOnNil,
            file: file,
            line: line
          )
          .pullback(
            state: toLocalState,
            action: toLocalAction,
            environment: toLocalEnvironment
          )
          .run(&state, action, environment)
          .cancellable(id: localEffectsId)
      } else {
        localEffects = .none
      }
      let effects = run(&state, action, environment)
      let newState = state
      let cancelEffects = shouldCancelEffects(oldState, newState)

      return .merge(
        localEffects,
        effects,
        cancelEffects ? .cancel(id: localEffectsId) : .none
      )
    }
  }
}

private struct EffectsId: Hashable {
  let id = UUID()
}
