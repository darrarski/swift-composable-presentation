import ComposableArchitecture
import Foundation

extension ReducerProtocol {
  /// Combines the reducer with another reducer that operates on optionally presented case of an enum.
  ///
  /// - All effects returned by the presented reducer are cancelled when presented `ID` changes.
  ///
  /// - Parameters:
  ///   - presentationID: Unique identifier for the presentation. Defaults to a new UUID.
  ///   - toEnum: Writable key-path from `State` to optional `Enum`.
  ///   - toCase: Case path from `Enum` to `Presented.State`.
  ///   - toPresentedID: Transformation from `Presented.State` to `ID`.
  ///   - toPresentedAction: A case path that can extract/embed presented action from parent.
  ///   - onPresent: An action run when presented reducer is presented. It takes current parent state and new presented state, and returns parent's action effect. Defaults to empty action.
  ///   - onDismiss: An action run when presented reducer is dismissed. It takes current parent state and old presented state, and returns parent's action effect. Defaults to empty action.
  ///   - presented: Presented reducer.
  /// - Returns: Combined reducer
  @inlinable
  public func presenting<ID: Hashable, Enum, Presented: ReducerProtocol>(
    presentationID: AnyHashable = UUID(),
    unwrapping toEnum: WritableKeyPath<State, Enum?>,
    case toCase: CasePath<Enum, Presented.State>,
    id toPresentedID: _PresentingCaseReducer<Self, Enum, ID, Presented>.ToPresentedID,
    action toPresentedAction: CasePath<Action, Presented.Action>,
    onPresent: _PresentingCaseReducer<Self, Enum, ID, Presented>.ActionHandler = .empty,
    onDismiss: _PresentingCaseReducer<Self, Enum, ID, Presented>.ActionHandler = .empty,
    @ReducerBuilderOf<Presented> presented: () -> Presented,
    file: StaticString = #file,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> _PresentingCaseReducer<Self, Enum, ID, Presented> {
    .init(
      presentationID: presentationID,
      parent: self,
      presented: presented(),
      toEnum: toEnum,
      toCase: toCase,
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

public struct _PresentingCaseReducer<
  Parent: ReducerProtocol,
  Enum,
  ID: Hashable,
  Presented: ReducerProtocol
>: ReducerProtocol {
  @usableFromInline
  let presentationID: AnyHashable

  @usableFromInline
  let parent: Parent

  @usableFromInline
  let presented: Presented

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
  let file: StaticString

  @usableFromInline
  let fileID: StaticString

  @usableFromInline
  let line: UInt

  @inlinable
  init(
    presentationID: AnyHashable,
    parent: Parent,
    presented: Presented,
    toEnum: WritableKeyPath<State, Enum?>,
    toCase: CasePath<Enum, Presented.State>,
    toPresentedID: ToPresentedID,
    toPresentedAction: CasePath<Parent.Action, Presented.Action>,
    onPresent: ActionHandler,
    onDismiss: ActionHandler,
    file: StaticString,
    fileID: StaticString,
    line: UInt
  ) {
    self.presentationID = presentationID
    self.parent = parent
    self.presented = presented
    self.toEnum = toEnum
    self.toCase = toCase
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
  ) -> Effect<Parent.Action, Never> {
    func toPresentedState(_ state: Parent.State) -> Presented.State? {
      guard let `enum` = state[keyPath: toEnum] else { return nil }
      return toCase.extract(from: `enum`)
    }

    let oldState = state
    let oldPresentedState = toPresentedState(oldState)
    let oldPresentedID = toPresentedID.run(oldPresentedState)

    let presentedEffectsID = PresentingReducerEffectId(
      presentationID: presentationID,
      presentedID: oldPresentedID
    )
    let shouldRunPresented = toPresentedAction.extract(from: action) != nil
    let presentedEffects: Effect<Action, Never>
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
                file: file,
                fileID: fileID,
                line: line
              )
          },
          file: file,
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

    var presentationEffects: [Effect<Action, Never>] = []
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
    public typealias Run = (inout Parent.State, Presented.State) -> Effect<Parent.Action, Never>

    /// An action that performs no state mutations and returns no effects.
    public static var empty: Self { .init { _, _ in .none } }

    /// Create action handler
    ///
    /// - Parameter run: Closure that handles the action. It takes inout `Parent.State`
    ///   and `Presented.State` and returns `Effect<Parent.Action, Never>`.
    public init(run: @escaping Run) {
      self.run = run
    }

    public var run: Run
  }
}