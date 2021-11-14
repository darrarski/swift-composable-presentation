import ComposableArchitecture

extension Reducer {
  /// Combines the reducer with another reducer that works on elements of `IdentifiedArray`.
  ///
  /// - All effects returned by another reducer will be canceled when `LocalState` becomes `nil`.
  ///
  /// - Parameters:
  ///   - localReducer: A reducer that works on `LocalState`, `LocalAction`, `LocalEnvironment`.
  ///   - breakpointOnNil: If `true`, raises `SIGTRAP` signal when an action is sent to the reducer
  ///       but state is `nil`. This is generally considered a logic error, as a child reducer cannot
  ///       process a child action for unavailable child state (defaults to `true`).
  ///   - toLocalState: A key path from `State` to `IdentifiedArrayOf<LocalState>`.
  ///   - toLocalAction: A case path that can extract/embed `LocalAction` from `Action`.
  ///   - toLocalEnvironment: A function that transforms `Environment` into `LocalEnvironment`.
  ///   - breakpointOnNil: If `true`, raises `SIGTRAP` signal when an action is sent to the reducer but the
  ///       identified array does not contain an element with the action's identifier. This is
  ///       generally considered a logic error, as a child reducer cannot process a child action
  ///       for unavailable child state. Default value is `true`.
  ///   - onRun: A closure invoked when another reducer is run. `LocalState.ID` is passed as an argument.
  ///       Defaults to an empty closure.
  ///   - onCancel: A closure invoked when effects produced by another reducer are being cancelled.
  ///       `LocalState.ID` is passed as an argument. Defaults to an empty closure.
  /// - Returns: A single, combined reducer.
  public func presenting<LocalState, LocalAction, LocalEnvironment>(
    forEach localReducer: Reducer<LocalState, LocalAction, LocalEnvironment>,
    state toLocalState: WritableKeyPath<State, IdentifiedArrayOf<LocalState>>,
    action toLocalAction: CasePath<Action, (LocalState.ID, LocalAction)>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment,
    breakpointOnNil: Bool = true,
    onRun: @escaping (LocalState.ID) -> Void = { _ in },
    onCancel: @escaping (LocalState.ID) -> Void = { _ in },
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Self {
    let presentationId = UUID()
    return Reducer { state, action, environment in
      let oldIds = state[keyPath: toLocalState].ids
      let localEffects: Effect<Action, Never>

      if let (id, _) = toLocalAction.extract(from: action) {
        onRun(id)
        localEffects = localReducer
          .forEach(
            state: toLocalState,
            action: toLocalAction,
            environment: toLocalEnvironment,
            breakpointOnNil: breakpointOnNil,
            file: file,
            line: line
          )
          .run(&state, action, environment)
          .cancellable(id: CancellationId(
            presentationId: presentationId,
            elementId: id
          ))
      } else {
        localEffects = .none
      }

      let effects = run(&state, action, environment)
      var cancellationEffects: [Effect<Action, Never>] = []
      let newIds = state[keyPath: toLocalState].ids
      let removedIds = oldIds.subtracting(newIds)

      removedIds.forEach { id in
        onCancel(id)
        cancellationEffects.append(.cancel(id: CancellationId(
          presentationId: presentationId,
          elementId: id
        )))
      }

      return .merge(
        localEffects,
        effects,
        .merge(cancellationEffects)
      )
    }
  }
}

private struct CancellationId: Hashable {
  var presentationId: UUID
  var elementId: AnyHashable
}
