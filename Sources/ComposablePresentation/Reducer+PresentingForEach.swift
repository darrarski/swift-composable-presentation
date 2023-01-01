import ComposableArchitecture
import Foundation

extension AnyReducer {
  /// Combines the reducer with a local reducer that works on elements of `IdentifiedArray`.
  ///
  /// - All effects returned by the local reducer when reducing a `LocalState` will be canceled
  ///   when the `LocalState` is removed from `IdentifiedArray`.
  /// - Inspired by [Reducer.presents function](https://github.com/pointfreeco/swift-composable-architecture/blob/9ec4b71e5a84f448dedb063a21673e4696ce135f/Sources/ComposableArchitecture/Reducer.swift#L549-L572) from `iso` branch of `swift-composable-architecture` repository.
  ///
  /// - Parameters:
  ///   - presentationID: Unique identifier for the presentation. Defaults to new UUID.
  ///   - localReducer: A reducer that works on `LocalState`, `LocalAction`, `LocalEnvironment`.
  ///   - toLocalState: A key path from `State` to `IdentifiedArrayOf<LocalState>`.
  ///   - toLocalAction: A case path that can extract/embed `LocalAction` from `Action`.
  ///   - toLocalEnvironment: A function that transforms `Environment` into `LocalEnvironment`.
  ///   - onPresent: An action run when `LocalState` is added to the array. Defaults to an empty action.
  ///   - onDismiss: An action run when `LocalState` is removed from the array. Defaults to an empty action.
  /// - Returns: A single, combined reducer.
  @available(
    iOS,
    deprecated: 9999.0,
    message: "This API has been soft-deprecated in favor of `ReducerProtocol.presentingForEach`."
  )
  @available(
    macOS,
    deprecated: 9999.0,
    message: "This API has been soft-deprecated in favor of `ReducerProtocol.presentingForEach`."
  )
  public func presenting<LocalState, LocalAction, LocalEnvironment>(
    presentationID: AnyHashable = UUID(),
    forEach localReducer: AnyReducer<LocalState, LocalAction, LocalEnvironment>,
    state toLocalState: WritableKeyPath<State, IdentifiedArrayOf<LocalState>>,
    action toLocalAction: CasePath<Action, (LocalState.ID, LocalAction)>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment,
    onPresent: ReducerPresentingForEachAction<LocalState.ID, State, Action, Environment> = .empty,
    onDismiss: ReducerPresentingForEachAction<LocalState.ID, State, Action, Environment> = .empty,
    file: StaticString = #fileID,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> Self {
    AnyReducer { state, action, env in
      _PresentingForEachReducer(
        parent: Reduce(AnyReducer(self.run), environment: env),
        toPresentationID: .value(presentationID),
        toElementState: toLocalState,
        toElementAction: toLocalAction,
        onPresent: .init { elementId, state in
          onPresent.run(elementId, &state, env)
        },
        onDismiss: .init { elementId, state in
          onDismiss.run(elementId, &state, env)
        },
        element: Reduce { state, action in
          localReducer.run(&state, action, toLocalEnvironment(env))
        }
      )
      .reduce(into: &state, action: action)
    }
  }
}

/// Describes for-each presentation action, like `onPresent` or `onDismiss`.
public struct ReducerPresentingForEachAction<ID, State, Action, Environment> {
  public typealias Run = (ID, inout State, Environment) -> Effect<Action, Never>

  /// An action that performs no state mutations and returns no effects.
  public static var empty: Self { .init { _, _, _ in .none } }

  public init(run: @escaping Run) {
    self.run = run
  }

  public var run: Run
}
