import ComposableArchitecture
import Foundation

extension ReducerProtocol {
  @inlinable
  public func presenting<ID: Hashable, Presented: ReducerProtocol>(
    state toPresentedState: PresentingReducerToPresentedState<State, Presented.State>,
    id toPresentedID: PresentingReducerToPresentedID<Presented.State, ID>,
    action toPresentedAction: CasePath<Action, Presented.Action>,
    onPresent: PresentingReducerAction<State, Presented.State, Action> = .empty,
    onDismiss: PresentingReducerAction<State, Presented.State, Action> = .empty,
    @ReducerBuilderOf<Presented> presented: () -> Presented,
    file: StaticString = #file,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> _PresentingReducer<Self, ID, Presented> {
    .init(
      reducerID: UUID(),
      parent: self,
      presented: presented(),
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
  Parent: ReducerProtocol,
  ID: Hashable,
  Presented: ReducerProtocol
>: ReducerProtocol {
  @usableFromInline
  let reducerID: UUID

  @usableFromInline
  let parent: Parent

  @usableFromInline
  let presented: Presented

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
    reducerID: UUID,
    parent: Parent,
    presented: Presented,
    toPresentedState: PresentingReducerToPresentedState<Parent.State, Presented.State>,
    toPresentedID: PresentingReducerToPresentedID<Presented.State, ID>,
    toPresentedAction: CasePath<Parent.Action, Presented.Action>,
    onPresent: PresentingReducerAction<Parent.State, Presented.State, Parent.Action>,
    onDismiss: PresentingReducerAction<Parent.State, Presented.State, Parent.Action>,
    file: StaticString,
    fileID: StaticString,
    line: UInt
  ) {
    self.reducerID = reducerID
    self.parent = parent
    self.presented = presented
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
  ) -> Effect<Parent.Action, Never> {
    let oldState = state
    let oldPresentedState = toPresentedState(oldState)
    let oldPresentedID = toPresentedID(oldPresentedState)

    let presentedEffectsID = PresentingReducerEffectId(
      reducerID: reducerID,
      presentedID: oldPresentedID
    )
    let shouldRunPresented = toPresentedAction.extract(from: action) != nil
    let presentedEffects: Effect<Action, Never>
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

public enum PresentingReducerToPresentedState<State, PresentedState> {
  case keyPath(WritableKeyPath<State, PresentedState?>)

  case casePath(CasePath<State, PresentedState>)

  public func callAsFunction(_ state: State) -> PresentedState? {
    switch self {
    case let .keyPath(keyPath):
      return state[keyPath: keyPath]
    case let .casePath(casePath):
      return casePath.extract(from: state)
    }
  }
}

public struct PresentingReducerToPresentedID<State, ID: Hashable> {
  public typealias Run = (State?) -> ID

  public static func notNil<State>() -> PresentingReducerToPresentedID<State, Bool> {
    .init { $0 != nil }
  }

  public static func keyPath(
    _ keyPath: KeyPath<State?, ID>
  ) -> PresentingReducerToPresentedID<State, ID> {
    .init { $0[keyPath: keyPath] }
  }

  public init(run: @escaping Run) {
    self.run = run
  }

  public var run: Run

  public func callAsFunction(_ state: State?) -> ID {
    run(state)
  }
}

public struct PresentingReducerAction<State, PresentedState, Action> {
  public typealias Run = (inout State, PresentedState) -> Effect<Action, Never>

  public static var empty: Self { .init { _, _ in .none } }

  public init(run: @escaping Run) {
    self.run = run
  }

  public var run: Run
}

public struct PresentingReducerEffectId<PresentedID: Hashable>: Hashable {
  @usableFromInline
  let reducerID: UUID

  @usableFromInline
  let presentedID: PresentedID

  @inlinable
  init(reducerID: UUID, presentedID: PresentedID) {
    self.reducerID = reducerID
    self.presentedID = presentedID
  }
}
