import ComposableArchitecture
import Foundation

extension Reducer {
  /// Combines the reducer with another reducer that operates on optionally presented state.
  ///
  /// - All effects returned by the presented reducer are cancelled when presented `ID` changes.
  ///
  /// - Parameters:
  ///   - toPresentationID: Transformation from `State` to unique identifier. Defaults to transformation that identifies object by type of `(State, Presented)`.
  ///   - state: `PresentingReducerToPresentedState` that can get/set presented state in parent.
  ///   - id: `PresentingReducerToPresentedID` that returns `ID` for given presented state.
  ///   - action: A case path that can extract/embed presented action from parent.
  ///   - onPresent: An action run when presented reducer is presented. It takes current parent state and new presented state, and returns parent's action effect. Defaults to empty action.
  ///   - onDismiss: An action run when presented reducer is dismissed. It takes current parent state and old presented state, and returns parent's action effect. Defaults to empty action.
  ///   - presented: Presented reducer.
  /// - Returns: Combined reducer.
  @inlinable
  public func presenting<ID, PresentedState, PresentedAction, Presented>(
    presentationID toPresentationID: ToPresentationID<State> = .typed(Presented.self),
    state toPresentedState: PresentingReducerToPresentedState<State, PresentedState>,
    id toPresentedID: PresentingReducerToPresentedID<PresentedState, ID>,
    action toPresentedAction: CasePath<Action, PresentedAction>,
    onPresent: PresentingReducerAction<State, PresentedState, Action> = .empty,
    onDismiss: PresentingReducerAction<State, PresentedState, Action> = .empty,
    @ReducerBuilder<PresentedState, PresentedAction> presented: () -> Presented,
    file: StaticString = #file,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> _PresentingReducer<Self, ID, Presented>
  where ID: Hashable,
        Presented: Reducer,
        Presented.State == PresentedState,
        Presented.Action == PresentedAction
  {
    .init(
      parent: self,
      presented: presented(),
      toPresentationID: toPresentationID,
      toPresentedState: toPresentedState,
      toPresentedID: toPresentedID,
      toPresentedAction: toPresentedAction,
      onPresent: onPresent,
      onDismiss: onDismiss,
      file: file,
      fileID: fileID,
      line: line
    )
  }
}

public struct _PresentingReducer<
  Parent: Reducer,
  ID: Hashable,
  Presented: Reducer
>: Reducer {
  @usableFromInline
  let parent: Parent

  @usableFromInline
  let presented: Presented

  @usableFromInline
  let toPresentationID: ToPresentationID<State>

  @usableFromInline
  let toPresentedState: PresentingReducerToPresentedState<Parent.State, Presented.State>

  @usableFromInline
  let toPresentedID: PresentingReducerToPresentedID<Presented.State, ID>

  @usableFromInline
  let toPresentedAction: CasePath<Parent.Action, Presented.Action>

  @usableFromInline
  let onPresent: PresentingReducerAction<Parent.State, Presented.State, Parent.Action>

  @usableFromInline
  let onDismiss: PresentingReducerAction<Parent.State, Presented.State, Parent.Action>

  @usableFromInline
  let file: StaticString

  @usableFromInline
  let fileID: StaticString

  @usableFromInline
  let line: UInt

  @inlinable
  init(
    parent: Parent,
    presented: Presented,
    toPresentationID: ToPresentationID<Parent.State>,
    toPresentedState: PresentingReducerToPresentedState<Parent.State, Presented.State>,
    toPresentedID: PresentingReducerToPresentedID<Presented.State, ID>,
    toPresentedAction: CasePath<Parent.Action, Presented.Action>,
    onPresent: PresentingReducerAction<Parent.State, Presented.State, Parent.Action>,
    onDismiss: PresentingReducerAction<Parent.State, Presented.State, Parent.Action>,
    file: StaticString,
    fileID: StaticString,
    line: UInt
  ) {
    self.parent = parent
    self.presented = presented
    self.toPresentationID = toPresentationID
    self.toPresentedState = toPresentedState
    self.toPresentedID = toPresentedID
    self.toPresentedAction = toPresentedAction
    self.onPresent = onPresent
    self.onDismiss = onDismiss
    self.file = file
    self.fileID = fileID
    self.line = line
  }

  @inlinable
  public func reduce(
    into state: inout Parent.State,
    action: Parent.Action
  ) -> Effect<Parent.Action> {
    let oldState = state
    let oldPresentedState = toPresentedState(oldState)
    let oldPresentedID = toPresentedID(oldPresentedState)

    let presentedEffectsID = PresentingReducerEffectId(
      presentationID: toPresentationID(oldState),
      presentedID: oldPresentedID
    )
    let shouldRunPresented = toPresentedAction.extract(from: action) != nil
    let presentedEffects: Effect<Action>
    if shouldRunPresented {
      switch toPresentedState {
      case let .keyPath(keyPath):
        presentedEffects = EmptyReducer()
          .ifLet(
            keyPath,
            action: toPresentedAction,
            then: { presented },
            file: file,
            fileID: fileID,
            line: line
          )
          .reduce(into: &state, action: action)
          .cancellable(id: presentedEffectsID)

      case let .casePath(casePath):
        presentedEffects = EmptyReducer()
          .ifCaseLet(
            casePath,
            action: toPresentedAction,
            then: { presented },
            file: file,
            fileID: fileID,
            line: line
          )
          .reduce(into: &state, action: action)
          .cancellable(id: presentedEffectsID)
      }
    } else {
      presentedEffects = .none
    }

    let effects = parent.reduce(into: &state, action: action)
    let newState = state
    let newPresentedState = toPresentedState(newState)
    let newPresentedID = toPresentedID(newPresentedState)

    var presentationEffects: [Effect<Action>] = []
    if oldPresentedID != newPresentedID {
      if let oldPresentedState = oldPresentedState {
        presentationEffects.append(onDismiss.run(&state, oldPresentedState))
        presentationEffects.append(.cancel(id: presentedEffectsID))
      }
      if let newPresentedState = newPresentedState {
        presentationEffects.append(onPresent.run(&state, newPresentedState))
      }
    }

    return .merge(
      presentedEffects,
      effects,
      .merge(presentationEffects)
    )
  }
}

/// `State` ↔ `PresentedState` transformation for `.presenting` higher order reducer.
public enum PresentingReducerToPresentedState<State, PresentedState> {
  /// A key path that can get/set `PresentedState` inside `State`.
  case keyPath(WritableKeyPath<State, PresentedState?>)

  /// A case path that can extract/embed `PresentedState` from `State`.
  case casePath(CasePath<State, PresentedState>)

  /// Returns optional `PresentedState` from provided `State`.
  /// - Parameter state: Parent state.
  /// - Returns: Presented state.
  public func callAsFunction(_ state: State) -> PresentedState? {
    switch self {
    case let .keyPath(keyPath):
      return state[keyPath: keyPath]
    case let .casePath(casePath):
      return casePath.extract(from: state)
    }
  }
}

/// `State` → `ID` transformation for `.presenting` higher order reducer.
public struct PresentingReducerToPresentedID<State, ID: Hashable> {
  public typealias Run = (State?) -> ID

  /// Identifies `State?` by just checking if it's not `nil`.
  ///
  /// - Use this with caution, as it only checks if the `State` is `nil`.
  /// - The effects returned by local reducer will only be cancelled when `State` becomes `nil.`
  ///
  /// - Returns: `PresentingReducerToPresentedID`
  public static func notNil<State>() -> PresentingReducerToPresentedID<State, Bool> {
    .init { $0 != nil }
  }

  /// Identifies `State?` based on `ID` retrieved by key path from `State?` to `ID`.
  ///
  /// - The effects returned by local reducer will be cancelled whenever `ID` changes.
  ///
  /// - Parameter `keyPath`: Key path from `State?` to `ID`.
  public static func keyPath(
    _ keyPath: KeyPath<State?, ID>
  ) -> PresentingReducerToPresentedID<State, ID> {
    .init { $0[keyPath: keyPath] }
  }

  public init(run: @escaping Run) {
    self.run = run
  }

  public var run: Run

  /// Returns `ID` for provided `State?`
  /// - Parameter state: Optional `State`
  /// - Returns: `ID`
  public func callAsFunction(_ state: State?) -> ID {
    run(state)
  }
}

/// Describes presentation action, like `onPresent` or `onDismiss`.
public struct PresentingReducerAction<State, PresentedState, Action> {
  public typealias Run = (inout State, PresentedState) -> Effect<Action>

  /// An action that performs no state mutations and returns no effects.
  public static var empty: Self { .init { _, _ in .none } }

  public init(run: @escaping Run) {
    self.run = run
  }

  public var run: Run
}

/// Effect produced by presented reducer within `.presenting` higher order reducer.
public struct PresentingReducerEffectId<PresentedID: Hashable>: Hashable {
  @usableFromInline
  let presentationID: AnyHashable

  @usableFromInline
  let presentedID: PresentedID

  @inlinable
  init(presentationID: AnyHashable, presentedID: PresentedID) {
    self.presentationID = presentationID
    self.presentedID = presentedID
  }
}
