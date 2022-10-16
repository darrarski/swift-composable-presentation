import ComposableArchitecture
import Foundation

extension Reducer {
  /// Combines the reducer with a local reducer that works on optionally presented `LocalState`.
  ///
  /// - All effects returned by the local reducer are cancelled when `LocalID` changes.
  ///
  /// - Parameters:
  ///   - localReducer: A reducer that works on `LocalState`, `LocalAction`, `LocalEnvironment`.
  ///   - toLocalState: `ReducerPresentingToLocalState` that can get/set `LocalState` inside `State`.
  ///   - toLocalID: `ReducerPresentingToLocalId` that returns `LocalID` for given `LocalState?`.
  ///   - toLocalAction: A case path that can extract/embed `LocalAction` from `Action`.
  ///   - toLocalEnvironment: A function that transforms `Environment` into `LocalEnvironment`.
  ///   - onPresent: An action run when `LocalState` is set to an honest value. It takes current `State`, new `LocalState`, and `Environment` as parameters and returns `Effect<Action, Never>`. Defaults to an empty action.
  ///   - onDismiss: An action run when `LocalState` becomes `nil`. It takes current `State`, old `LocalState`, and `Environment` as parameters and returns `Effect<Action, Never>`. Defaults to an empty action.
  /// - Returns: A single, combined reducer.
  @available(
    iOS,
    deprecated: 9999.0,
    message: "This API has been soft-deprecated in favor of `ReducerProtocol.presenting`."
  )
  @available(
    macOS,
    deprecated: 9999.0,
    message: "This API has been soft-deprecated in favor of `ReducerProtocol.presenting`."
  )
  public func presenting<LocalState, LocalID: Hashable, LocalAction, LocalEnvironment>(
    _ localReducer: Reducer<LocalState, LocalAction, LocalEnvironment>,
    state toLocalState: ReducerPresentingToLocalState<State, LocalState>,
    id toLocalId: ReducerPresentingToLocalId<LocalState, LocalID>,
    action toLocalAction: CasePath<Action, LocalAction>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment,
    onPresent: ReducerPresentingAction<State, LocalState, Action, Environment> = .empty,
    onDismiss: ReducerPresentingAction<State, LocalState, Action, Environment> = .empty,
    file: StaticString = #fileID,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> Self {
    let reducerId = UUID()
    return Reducer { state, action, env in
      _PresentingReducer(
        reducerID: reducerId,
        parent: Reduce(AnyReducer(self.run), environment: env),
        presented: Reduce { state, action in
          localReducer.run(&state, action, toLocalEnvironment(env))
        },
        toPresentedState: {
          switch toLocalState {
          case .keyPath(let keyPath): return .keyPath(keyPath)
          case .casePath(let casePath): return .casePath(casePath)
          }
        }(),
        toPresentedID: .init(run: toLocalId.run),
        toPresentedAction: toLocalAction,
        onPresent: .init { state, presentedState in
          onPresent.run(&state, presentedState, env)
        },
        onDismiss: .init { state, presentedState in
          onDismiss.run(&state, presentedState, env)
        },
        file: file,
        fileID: fileID,
        line: line
      )
      .reduce(into: &state, action: action)
    }
  }
}

/// `State` ↔ `LocalState` transformation for `.presenting` higher order reducer.
public enum ReducerPresentingToLocalState<State, LocalState> {
  /// A key path that can get/set `LocalState` inside `State`.
  case keyPath(WritableKeyPath<State, LocalState?>)

  /// A case path that can extract/embed `LocalState` from `State`.
  case casePath(CasePath<State, LocalState>)

  /// Returns optional `LocalState` from provided `State`.
  /// - Parameter state: `State`
  /// - Returns: Optional `LocalState`
  public func callAsFunction(_ state: State) -> LocalState? {
    switch self {
    case let .keyPath(keyPath):
      return state[keyPath: keyPath]
    case let .casePath(casePath):
      return casePath.extract(from: state)
    }
  }
}

/// `LocalState` → `LocalID` transformation for `.presenting` higher order reducer.
public struct ReducerPresentingToLocalId<LocalState, LocalId: Hashable> {
  public typealias Run = (LocalState?) -> LocalId

  /// Identifies `LocalState?` by just checking if it's not `nil`.
  ///
  /// - Use this with caution, as it only checks if the `LocalState` is `nil`.
  /// - The effects returned by local reducer will only be cancelled when `LocalState` becomes `nil.`
  ///
  /// - Returns: ReducerPresentingToLocalId
  public static func notNil<State>() -> ReducerPresentingToLocalId<State, Bool> {
    .init { $0 != nil }
  }

  /// Identifies `LocalState` based on `ID` and key path from `LocalState?` to `LocalID`.
  ///
  /// - The effects returned by local reducer will be cancelled whenever `LocalID` changes.
  ///
  /// - Parameter `keyPath`: Key path from `LocalState?` to `LocalID`.
  public static func keyPath(_ keyPath: KeyPath<LocalState?, LocalId>) -> ReducerPresentingToLocalId<LocalState, LocalId> {
    .init { $0[keyPath: keyPath] }
  }

  public init(run: @escaping Run) {
    self.run = run
  }

  /// Returns `LocalId` for provided `LocalState?`
  /// - Parameter localState: Optional `LocalState`
  /// - Returns: `LocalId`
  public func callAsFunction(_ localState: LocalState?) -> LocalId {
    run(localState)
  }

  public var run: Run
}

/// Describes presentation action, like `onPresent` or `onDismiss`.
public struct ReducerPresentingAction<State, LocalState, Action, Environment> {
  public typealias Run = (inout State, LocalState, Environment) -> Effect<Action, Never>

  /// An action that performs no state mutations and returns no effects.
  public static var empty: Self { .init { _, _, _ in .none } }

  public init(run: @escaping Run) {
    self.run = run
  }

  public var run: Run
}
