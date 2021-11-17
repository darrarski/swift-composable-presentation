import ComposableArchitecture

extension Reducer {
  /// Combines the reducer with another reducer that works on optionally presented `LocalState`.
  ///
  /// - All effects returned by another reducer will be canceled when `LocalState` becomes `nil`.
  /// - Inspired by [Reducer.presents function](https://github.com/pointfreeco/swift-composable-architecture/blob/9ec4b71e5a84f448dedb063a21673e4696ce135f/Sources/ComposableArchitecture/Reducer.swift#L549-L572) from `iso` branch of `swift-composable-architecture` repository.
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
    presenting(
      localReducer,
      state: .keyPath(toLocalState),
      action: toLocalAction,
      environment: toLocalEnvironment,
      breakpointOnNil: breakpointOnNil,
      onRun: onRun,
      onCancel: onCancel,
      file: file,
      line: line
    )
  }

  /// Combines the reducer with another reducer that works on optionally presented `LocalState`.
  ///
  /// - All effects returned by another reducer will be canceled when `LocalState` becomes `nil`.
  ///
  /// - Parameters:
  ///   - localReducer: A reducer that works on `LocalState`, `LocalAction`, `LocalEnvironment`.
  ///   - toLocalState: A case path that can extract/embed `LocalState` from `State`.
  ///   - toLocalAction: A case path that can extract/embed `LocalAction` from `Action`.
  ///   - toLocalEnvironment: A function that transforms `Environment` into `LocalEnvironment`.
  ///   - breakpointOnNil: If `true`, raises `SIGTRAP` signal when an action is sent to the reducer
  ///       but state is in invalid case. This is generally considered a logic error, as a child reducer cannot
  ///       process a child action for unavailable child state. Default value is `true`.
  ///   - onRun: A closure invoked when another reducer is run. Defaults to an empty closure.
  ///   - onCancel: A closure invoked when effects produced by another reducer are being cancelled.
  ///       Defaults to an empty closure.
  /// - Returns: A single, combined reducer.
  public func presenting<LocalState, LocalAction, LocalEnvironment>(
    _ localReducer: Reducer<LocalState, LocalAction, LocalEnvironment>,
    state toLocalState: CasePath<State, LocalState>,
    action toLocalAction: CasePath<Action, LocalAction>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment,
    breakpointOnNil: Bool = true,
    onRun: @escaping () -> Void = {},
    onCancel: @escaping () -> Void = {},
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Self {
    presenting(
      localReducer,
      state: .casePath(toLocalState),
      action: toLocalAction,
      environment: toLocalEnvironment,
      breakpointOnNil: breakpointOnNil,
      onRun: onRun,
      onCancel: onCancel,
      file: file,
      line: line
    )
  }

  func presenting<LocalState, LocalAction, LocalEnvironment>(
    _ localReducer: Reducer<LocalState, LocalAction, LocalEnvironment>,
    state toLocalState: ReducerPresentingToLocalState<State, LocalState>,
    action toLocalAction: CasePath<Action, LocalAction>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment,
    breakpointOnNil: Bool = true,
    onRun: @escaping () -> Void = {},
    onCancel: @escaping () -> Void = {},
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Self {
    let localEffectsId = ReducerPresentingEffectId()

    func shouldRun(for action: Action) -> Bool {
      let shouldRun = toLocalAction.extract(from: action) != nil
      if shouldRun { onRun() }
      return shouldRun
    }

    func shouldCancelEffects(for oldState: State, _ newState: State) -> Bool {
      let wasPresented = toLocalState(oldState) != nil
      let isDismissed = toLocalState(newState) == nil
      let shouldCancel = wasPresented && isDismissed
      if shouldCancel { onCancel() }
      return shouldCancel
    }

    return Reducer { state, action, environment in
      let oldState = state
      let localEffects: Effect<Action, Never>
      if shouldRun(for: action) {
        localEffects = localReducer
          .pullback(
            state: toLocalState,
            action: toLocalAction,
            environment: toLocalEnvironment,
            breakpointOnNil: breakpointOnNil,
            file: file,
            line: line
          )
          .run(&state, action, environment)
          .cancellable(id: localEffectsId)
      } else {
        localEffects = .none
      }
      let effects = run(&state, action, environment)
      let newState = state
      let cancelEffects = shouldCancelEffects(for: oldState, newState)

      return .merge(
        localEffects,
        effects,
        cancelEffects ? .cancel(id: localEffectsId) : .none
      )
    }
  }

  func pullback<GlobalState, GlobalAction, GlobalEnvironment>(
    state toLocalState: ReducerPresentingToLocalState<GlobalState, State>,
    action toLocalAction: CasePath<GlobalAction, Action>,
    environment toLocalEnvironment: @escaping (GlobalEnvironment) -> Environment,
    breakpointOnNil: Bool,
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Reducer<GlobalState, GlobalAction, GlobalEnvironment> {
    switch toLocalState {
    case let .keyPath(keyPath):
      return optional(
        breakpointOnNil: breakpointOnNil,
        file: file,
        line: line
      ).pullback(
        state: keyPath,
        action: toLocalAction,
        environment: toLocalEnvironment
      )

    case let .casePath(casePath):
      return pullback(
        state: casePath,
        action: toLocalAction,
        environment: toLocalEnvironment,
        breakpointOnNil: breakpointOnNil,
        file: file,
        line: line
      )
    }
  }
}

enum ReducerPresentingToLocalState<State, LocalState> {
  case keyPath(WritableKeyPath<State, LocalState?>)
  case casePath(CasePath<State, LocalState>)

  func callAsFunction(_ state: State) -> LocalState? {
    switch self {
    case let .keyPath(keyPath):
      return state[keyPath: keyPath]
    case let .casePath(casePath):
      return casePath.extract(from: state)
    }
  }
}

struct ReducerPresentingEffectId: Hashable {
  let uuid = UUID()
}
