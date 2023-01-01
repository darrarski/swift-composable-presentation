import ComposableArchitecture

extension AnyReducer {
  /// Combines the reducer with a local reducer that works on optionally presented `LocalState`.
  ///
  /// - All effects returned by the local reducer will be canceled when `LocalState` becomes `nil`.
  /// - Inspired by [Reducer.presents function](https://github.com/pointfreeco/swift-composable-architecture/blob/9ec4b71e5a84f448dedb063a21673e4696ce135f/Sources/ComposableArchitecture/Reducer.swift#L549-L572) from `iso` branch of `swift-composable-architecture` repository.
  ///
  /// - Parameters:
  ///   - localReducer: A reducer that works on `LocalState`, `LocalAction`, `LocalEnvironment`.
  ///   - toLocalState: A key path that can get/set `LocalState` inside `State`.
  ///   - toLocalAction: A case path that can extract/embed `LocalAction` from `Action`.
  ///   - toLocalEnvironment: A function that transforms `Environment` into `LocalEnvironment`.
  ///   - onPresent: An action run when `LocalState` is set to an honest value. Defaults to an empty action.
  ///   - onDismiss: An action run when `LocalState` becomes `nil`. Defaults to an empty action.
  ///   - breakpointOnNil: If `true`, raises `SIGTRAP` signal when an action is sent to the reducer
  ///       but state is `nil`. This is generally considered a logic error, as a child reducer cannot
  ///       process a child action for unavailable child state. Default value is `true`.
  /// - Returns: A single, combined reducer.
  @available(*, deprecated, message: """
  Use `Reducer.presenting` function that takes `ReducerPresentingToLocalState` as `state` parameter.

  You can wrap currently passed value with `.keyPath(...)` to fix this warning.
  """)
  public func presenting<LocalState, LocalAction, LocalEnvironment>(
    _ localReducer: Reducer<LocalState, LocalAction, LocalEnvironment>,
    state toLocalState: WritableKeyPath<State, LocalState?>,
    action toLocalAction: CasePath<Action, LocalAction>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment,
    onPresent: ReducerPresentingAction<State, LocalState, Action, Environment> = .empty,
    onDismiss: ReducerPresentingAction<State, LocalState, Action, Environment> = .empty,
    breakpointOnNil: Bool = true,
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Self {
    presenting(
      localReducer,
      state: .keyPath(toLocalState),
      action: toLocalAction,
      environment: toLocalEnvironment,
      onPresent: onPresent,
      onDismiss: onDismiss,
      breakpointOnNil: breakpointOnNil,
      file: file,
      line: line
    )
  }

  /// Combines the reducer with a local reducer that works on optionally presented `LocalState`.
  ///
  /// - All effects returned by the local reducer will be canceled when `LocalState` becomes `nil`.
  /// - Inspired by [Reducer.presents function](https://github.com/pointfreeco/swift-composable-architecture/blob/9ec4b71e5a84f448dedb063a21673e4696ce135f/Sources/ComposableArchitecture/Reducer.swift#L549-L572) from `iso` branch of `swift-composable-architecture` repository.
  ///
  /// - Parameters:
  ///   - localReducer: A reducer that works on `LocalState`, `LocalAction`, `LocalEnvironment`.
  ///   - toLocalState: A key path that can get/set `LocalState` inside `State`.
  ///   - toLocalAction: A case path that can extract/embed `LocalAction` from `Action`.
  ///   - toLocalEnvironment: A function that transforms `Environment` into `LocalEnvironment`.
  ///   - onPresent: An action run when `LocalState` is set to an honest value. Defaults to an empty action.
  ///   - onDismiss: An action run when `LocalState` becomes `nil`. Defaults to an empty action.
  ///   - breakpointOnNil: If `true`, raises `SIGTRAP` signal when an action is sent to the reducer
  ///       but state is `nil`. This is generally considered a logic error, as a child reducer cannot
  ///       process a child action for unavailable child state. Default value is `true`.
  /// - Returns: A single, combined reducer.
  @available(*, deprecated, message: """
  Use `Reducer.presenting` function that takes `ReducerPresentingToLocalState` as `state` parameter.

  You can wrap currently passed value with `.casePath(...)` to fix this warning.
  """)
  public func presenting<LocalState, LocalAction, LocalEnvironment>(
    _ localReducer: Reducer<LocalState, LocalAction, LocalEnvironment>,
    state toLocalState: CasePath<State, LocalState>,
    action toLocalAction: CasePath<Action, LocalAction>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment,
    onPresent: ReducerPresentingAction<State, LocalState, Action, Environment> = .empty,
    onDismiss: ReducerPresentingAction<State, LocalState, Action, Environment> = .empty,
    breakpointOnNil: Bool = true,
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Self {
    presenting(
      localReducer,
      state: .casePath(toLocalState),
      action: toLocalAction,
      environment: toLocalEnvironment,
      onPresent: onPresent,
      onDismiss: onDismiss,
      breakpointOnNil: breakpointOnNil,
      file: file,
      line: line
    )
  }

  /// Combines the reducer with a local reducer that works on elements of `IdentifiedArray`.
  ///
  /// - All effects returned by the local reducer when reducing a `LocalState` will be canceled
  ///   when the `LocalState` is removed from `IdentifiedArray`.
  /// - Inspired by [Reducer.presents function](https://github.com/pointfreeco/swift-composable-architecture/blob/9ec4b71e5a84f448dedb063a21673e4696ce135f/Sources/ComposableArchitecture/Reducer.swift#L549-L572) from `iso` branch of `swift-composable-architecture` repository.
  ///
  /// - Parameters:
  ///   - localReducer: A reducer that works on `LocalState`, `LocalAction`, `LocalEnvironment`.
  ///   - toLocalState: A key path from `State` to `IdentifiedArrayOf<LocalState>`.
  ///   - toLocalAction: A case path that can extract/embed `LocalAction` from `Action`.
  ///   - toLocalEnvironment: A function that transforms `Environment` into `LocalEnvironment`.
  ///   - onPresent: An action run when `LocalState` is added to the array. Defaults to an empty action.
  ///   - onDismiss: An action run when `LocalState` is removed from the array. Defaults to an empty action.
  ///   - breakpointOnNil: If `true`, raises `SIGTRAP` signal when an action is sent to the reducer but the
  ///       identified array does not contain an element with the action's identifier. This is
  ///       generally considered a logic error, as a child reducer cannot process a child action
  ///       for unavailable child state. Default value is `true`.
  /// - Returns: A single, combined reducer.
  @available(*, deprecated, message: """
  'Reducer.presenting' no longer takes a 'breakpointOnNil' argument.
  """)
  public func presenting<LocalState, LocalAction, LocalEnvironment>(
    forEach localReducer: Reducer<LocalState, LocalAction, LocalEnvironment>,
    state toLocalState: WritableKeyPath<State, IdentifiedArrayOf<LocalState>>,
    action toLocalAction: CasePath<Action, (LocalState.ID, LocalAction)>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment,
    onPresent: ReducerPresentingForEachAction<LocalState.ID, State, Action, Environment> = .empty,
    onDismiss: ReducerPresentingForEachAction<LocalState.ID, State, Action, Environment> = .empty,
    breakpointOnNil: Bool,
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Self {
    presenting(
      forEach: localReducer,
      state: toLocalState,
      action: toLocalAction,
      environment: toLocalEnvironment,
      onPresent: onPresent,
      onDismiss: onDismiss,
      file: file,
      line: line
    )
  }

  /// Combines the reducer with a local reducer that works on optionally presented `LocalState`.
  ///
  /// - All effects returned by the local reducer will be canceled when `LocalState` becomes `nil`.
  /// - Inspired by [Reducer.presents function](https://github.com/pointfreeco/swift-composable-architecture/blob/9ec4b71e5a84f448dedb063a21673e4696ce135f/Sources/ComposableArchitecture/Reducer.swift#L549-L572) from `iso` branch of `swift-composable-architecture` repository.
  ///
  /// - Parameters:
  ///   - localReducer: A reducer that works on `LocalState`, `LocalAction`, `LocalEnvironment`.
  ///   - toLocalState: `ReducerPresentingToLocalState` that can get/set `LocalState` inside `State`.
  ///   - toLocalAction: A case path that can extract/embed `LocalAction` from `Action`.
  ///   - toLocalEnvironment: A function that transforms `Environment` into `LocalEnvironment`.
  ///   - onPresent: An action run when `LocalState` is set to an honest value. Defaults to an empty action.
  ///   - onDismiss: An action run when `LocalState` becomes `nil`. Defaults to an empty action.
  ///   - breakpointOnNil: If `true`, raises `SIGTRAP` signal when an action is sent to the reducer
  ///       but state is `nil`. This is generally considered a logic error, as a child reducer cannot
  ///       process a child action for unavailable child state. Default value is `true`.
  /// - Returns: A single, combined reducer.
  @available(*, deprecated, message: """
  'Reducer.presenting' no longer takes a 'breakpointOnNil' argument.
  """)
  public func presenting<LocalState, LocalAction, LocalEnvironment>(
    _ localReducer: Reducer<LocalState, LocalAction, LocalEnvironment>,
    state toLocalState: ReducerPresentingToLocalState<State, LocalState>,
    action toLocalAction: CasePath<Action, LocalAction>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment,
    onPresent: ReducerPresentingAction<State, LocalState, Action, Environment> = .empty,
    onDismiss: ReducerPresentingAction<State, LocalState, Action, Environment> = .empty,
    breakpointOnNil: Bool,
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Self {
    presenting(
      localReducer,
      state: toLocalState,
      action: toLocalAction,
      environment: toLocalEnvironment,
      onPresent: onPresent,
      onDismiss: onDismiss,
      file: file,
      line: line
    )
  }

  /// Combines the reducer with a local reducer that works on optionally presented `LocalState`.
  ///
  /// - All effects returned by the local reducer will be canceled when `LocalState` becomes `nil`.
  /// - Inspired by [Reducer.presents function](https://github.com/pointfreeco/swift-composable-architecture/blob/9ec4b71e5a84f448dedb063a21673e4696ce135f/Sources/ComposableArchitecture/Reducer.swift#L549-L572) from `iso` branch of `swift-composable-architecture` repository.
  ///
  /// - Parameters:
  ///   - localReducer: A reducer that works on `LocalState`, `LocalAction`, `LocalEnvironment`.
  ///   - toLocalState: `ReducerPresentingToLocalState` that can get/set `LocalState` inside `State`.
  ///   - toLocalAction: A case path that can extract/embed `LocalAction` from `Action`.
  ///   - toLocalEnvironment: A function that transforms `Environment` into `LocalEnvironment`.
  ///   - onPresent: An action run when `LocalState` is set to an honest value. Defaults to an empty action.
  ///   - onDismiss: An action run when `LocalState` becomes `nil`. Defaults to an empty action.
  /// - Returns: A single, combined reducer.
  @available(*, deprecated, message: """
  'Reducer.presenting' requires 'id' parameter.
  Using 'ReducerPresentingToLocalId.notNil()` as a fallback.
  Explicitly provide `id` to fix this warning.
  """)
  public func presenting<LocalState, LocalAction, LocalEnvironment>(
    _ localReducer: Reducer<LocalState, LocalAction, LocalEnvironment>,
    state toLocalState: ReducerPresentingToLocalState<State, LocalState>,
    action toLocalAction: CasePath<Action, LocalAction>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment,
    onPresent: ReducerPresentingAction<State, LocalState, Action, Environment> = .empty,
    onDismiss: ReducerPresentingAction<State, LocalState, Action, Environment> = .empty,
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Self {
    presenting(
      localReducer,
      state: toLocalState,
      id: .notNil(),
      action: toLocalAction,
      environment: toLocalEnvironment,
      onPresent: onPresent,
      onDismiss: onDismiss,
      file: file,
      line: line
    )
  }
}

extension ReducerPresentingAction {
  @available(*, deprecated, message: """
  'ReducerPresentingAction.Run' expects three parameters: 'inout State', 'LocalState', and 'Environment'.
  """)
  public init(run: @escaping (inout State, Environment) -> Effect<Action, Never>) {
    self.init { state, _, environment in
      run(&state, environment)
    }
  }
}
