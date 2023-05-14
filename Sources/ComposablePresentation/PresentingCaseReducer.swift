import ComposableArchitecture
import Foundation

extension Reducer {
  /// Combines the reducer with another reducer that operates on optionally presented case of an enum.
  ///
  /// - All effects returned by the presented reducer are cancelled when presented `ID` changes.
  ///
  /// - Parameters:
  ///   - toPresentationID: Transformation from `State` to unique identifier. Defaults to transformation that identifies object by type of `(State, Presented)`.
  ///   - toEnum: Writable key-path from `State` to optional `Enum`.
  ///   - toCase: Case path from `Enum` to `Presented.State`.
  ///   - toPresentedID: Transformation from `Presented.State` to `ID`.
  ///   - toPresentedAction: A case path that can extract/embed presented action from parent.
  ///   - onPresent: An action run when presented reducer is presented. It takes current parent state and new presented state, and returns parent's action effect. Defaults to empty action.
  ///   - onDismiss: An action run when presented reducer is dismissed. It takes current parent state and old presented state, and returns parent's action effect. Defaults to empty action.
  ///   - presented: Presented reducer.
  /// - Returns: Combined reducer
  @inlinable
  public func presenting<ID, Enum, PresentedState, PresentedAction, Presented>(
    presentationID toPresentationID: ToPresentationID<State> = .typed(Presented.self),
    unwrapping toEnum: WritableKeyPath<State, Enum?>,
    case toCase: CasePath<Enum, PresentedState>,
    id toPresentedID: _PresentingCaseReducer<Self, Enum, ID, Presented>.ToPresentedID,
    action toPresentedAction: CasePath<Action, PresentedAction>,
    onPresent: _PresentingCaseReducer<Self, Enum, ID, Presented>.ActionHandler = .empty,
    onDismiss: _PresentingCaseReducer<Self, Enum, ID, Presented>.ActionHandler = .empty,
    @ReducerBuilder<PresentedState, PresentedAction> presented: () -> Presented,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> _PresentingCaseReducer<Self, Enum, ID, Presented>
  where ID: Hashable,
        Presented: Reducer,
        Presented.State == PresentedState,
        Presented.Action == PresentedAction
  {
    .init(
      parent: self,
      presented: presented(),
      toPresentationID: toPresentationID,
      toEnum: toEnum,
      toCase: toCase,
      toPresentedID: toPresentedID,
      toPresentedAction: toPresentedAction,
      onPresent: onPresent,
      onDismiss: onDismiss,
      fileID: fileID,
      line: line
    )
  }
}

public struct _PresentingCaseReducer<
  Parent: Reducer,
  Enum,
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
  let toEnum: WritableKeyPath<Parent.State, Enum?>

  @usableFromInline
  let toCase: CasePath<Enum, Presented.State>

  @usableFromInline
  let toPresentedID: ToPresentedID

  @usableFromInline
  let toPresentedAction: CasePath<Parent.Action, Presented.Action>

  @usableFromInline
  let onPresent: ActionHandler

  @usableFromInline
  let onDismiss: ActionHandler

  @usableFromInline
  let fileID: StaticString

  @usableFromInline
  let line: UInt

  @inlinable
  init(
    parent: Parent,
    presented: Presented,
    toPresentationID: ToPresentationID<State>,
    toEnum: WritableKeyPath<State, Enum?>,
    toCase: CasePath<Enum, Presented.State>,
    toPresentedID: ToPresentedID,
    toPresentedAction: CasePath<Parent.Action, Presented.Action>,
    onPresent: ActionHandler,
    onDismiss: ActionHandler,
    fileID: StaticString,
    line: UInt
  ) {
    self.parent = parent
    self.presented = presented
    self.toPresentationID = toPresentationID
    self.toEnum = toEnum
    self.toCase = toCase
    self.toPresentedID = toPresentedID
    self.toPresentedAction = toPresentedAction
    self.onPresent = onPresent
    self.onDismiss = onDismiss
    self.fileID = fileID
    self.line = line
  }

  @inlinable
  public func reduce(
    into state: inout Parent.State,
    action: Parent.Action
  ) -> Effect<Parent.Action> {
    func toPresentedState(_ state: Parent.State) -> Presented.State? {
      guard let `enum` = state[keyPath: toEnum] else { return nil }
      return toCase.extract(from: `enum`)
    }

    let oldState = state
    let oldPresentedState = toPresentedState(oldState)
    let oldPresentedID = toPresentedID.run(oldPresentedState)

    let presentedEffectsID = PresentingReducerEffectId(
      presentationID: toPresentationID(oldState),
      presentedID: oldPresentedID
    )
    let shouldRunPresented = toPresentedAction.extract(from: action) != nil
    let presentedEffects: Effect<Action>
    if shouldRunPresented {
      presentedEffects = EmptyReducer()
        .ifLet(
          toEnum,
          action: toPresentedAction,
          then: {
            EmptyReducer()
              .ifCaseLet(
                toCase,
                action: /.self,
                then: { presented },
                fileID: fileID,
                line: line
              )
          },
          fileID: fileID,
          line: line
        )
        .reduce(into: &state, action: action)
        .cancellable(id: presentedEffectsID)
    } else {
      presentedEffects = .none
    }

    let effects = parent.reduce(into: &state, action: action)
    let newState = state
    let newPresentedState = toPresentedState(newState)
    let newPresentedID = toPresentedID.run(newPresentedState)

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

extension _PresentingCaseReducer {
  /// `Presented.State?` → `ID` transformation
  public struct ToPresentedID {
    public typealias Run = (Presented.State?) -> ID

    /// Identifies `Presented.State?` by just checking if it's not `nil`.
    ///
    /// - Use this with caution, as it only checks if the `Presented.State?` is `nil`.
    /// - The effects returned by local reducer will only be cancelled when `Presented.State?` becomes `nil.`
    ///
    /// - Returns: `ToPresentedID` transformation.
    public static func notNil() -> ToPresentedID where ID == Bool {
      .init { $0 != nil }
    }

    /// Identifies `Presented.State?` based on `ID` retrieved by key path from `Presented.State?` to `ID`.
    ///
    /// - The effects returned by local reducer will be cancelled whenever `ID` changes.
    ///
    /// - Parameter `keyPath`: Key path from `Presented.State?` to `ID`.
    ///
    /// - Returns: `ToPresentedID` transformation.
    public static func keyPath(_ keyPath: KeyPath<Presented.State?, ID>) -> ToPresentedID {
      .init { $0[keyPath: keyPath] }
    }

    public var run: Run
  }
}

extension _PresentingCaseReducer {
  /// Handles presentation action, like `onPresent` or `onDismiss`.
  public struct ActionHandler {
    public typealias Run = (inout Parent.State, Presented.State) -> Effect<Parent.Action>

    /// An action that performs no state mutations and returns no effects.
    public static var empty: Self { .init { _, _ in .none } }

    /// Create action handler
    ///
    /// - Parameter run: Closure that handles the action. It takes inout `Parent.State`
    ///   and `Presented.State` and returns `Effect<Parent.Action>`.
    public init(run: @escaping Run) {
      self.run = run
    }

    public var run: Run
  }
}
