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
    state toLocalState: WritableKeyPath<State, Presented<LocalState>>,
    action toLocalAction: CasePath<Action, LocalAction>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment
  ) -> Self {
    combined(
      with: localReducer.optional(breakpointOnNil: breakpointOnNil).pullback(
        state: toLocalState.appending(path: \.wrappedValue),
        action: toLocalAction,
        environment: toLocalEnvironment
      ),
      runs: { state, action in
        toLocalAction.extract(from: action) != nil
      },
      cancelEffects: { state in
        let shouldCancel = state[keyPath: toLocalState].shouldCancel
#if DEBUG
        if shouldCancel {
          presentedKeyPathCancelCounter += 1
        }
#endif
        if shouldCancel {
          state[keyPath: toLocalState].hadState = false
        }
        return shouldCancel
      }
    )
  }
}

#if DEBUG
var presentedKeyPathCancelCounter: Int = 0
#endif

@propertyWrapper
/// Property Wrapper that manages state for presented data. The wrapped value
/// can be nil or non-nil to indicate presentation. When it becomes nil,
/// the presentation's effects are cleaned up automatically.
public struct Presented<State: Equatable> {

  public init(wrappedValue: State?) {
    self.wrappedValue = wrappedValue
  }

  public var wrappedValue: State? {
    didSet {
      hadState = wrappedValue != nil || hadState
    }
  }

  public var projectedValue: Self {
    get { self }
    set { self = newValue }
  }

  fileprivate var hadState: Bool = false
}

fileprivate extension Presented {
  var hasState: Bool {
    wrappedValue != nil
  }
  var shouldCancel: Bool {
    hadState && !hasState
  }
}

extension Presented: Equatable {
  // Don't expose `hadState` to TCA TestStore assertions.
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    lhs.wrappedValue == rhs.wrappedValue
  }
}
