import ComposableArchitecture

extension Reducer {
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
  /// - Returns: A single, combined reducer.
  public func presenting<LocalState, LocalAction, LocalEnvironment>(
    forEach localReducer: Reducer<LocalState, LocalAction, LocalEnvironment>,
    state toLocalState: WritableKeyPath<State, IdentifiedArrayOf<LocalState>>,
    action toLocalAction: CasePath<Action, (LocalState.ID, LocalAction)>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment,
    onPresent: ReducerPresentingForEachAction<LocalState.ID, State, Action, Environment> = .empty,
    onDismiss: ReducerPresentingForEachAction<LocalState.ID, State, Action, Environment> = .empty,
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Self {
    let presentationId = UUID()

    func elementId(for action: Action) -> LocalState.ID? {
      guard let (id, _) = toLocalAction.extract(from: action) else {
        return nil
      }
      return id
    }

    func effectId(for id: LocalState.ID) -> ReducerPresentingForEachEffectId {
      .init(presentationId: presentationId, elementId: id)
    }

    return Reducer { state, action, environment in
      let oldIds = state[keyPath: toLocalState].ids
      let localEffects: Effect<Action, Never>

      if let id = elementId(for: action) {
        localEffects = localReducer
          .forEach(
            state: toLocalState,
            action: toLocalAction,
            environment: toLocalEnvironment,
            file: file,
            line: line
          )
          .run(&state, action, environment)
          .cancellable(id: effectId(for: id))
      } else {
        localEffects = .none
      }

      let effects = run(&state, action, environment)
      let newIds = state[keyPath: toLocalState].ids
      let presentedIds = newIds.subtracting(oldIds)
      let dismissedIds = oldIds.subtracting(newIds)
      var presentationEffects: [Effect<Action, Never>] = []

      dismissedIds.forEach { id in
        presentationEffects.append(onDismiss.run(id, &state, environment))
        presentationEffects.append(.cancel(id: effectId(for: id)))
      }

      presentedIds.forEach { id in
        presentationEffects.append(onPresent.run(id, &state, environment))
      }

      return .merge(
        localEffects,
        effects,
        .merge(presentationEffects)
      )
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

struct ReducerPresentingForEachEffectId: Hashable {
  var presentationId: UUID
  var elementId: AnyHashable
}
