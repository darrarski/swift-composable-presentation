import ComposableArchitecture
import Foundation

extension ReducerProtocol {
  @inlinable
  public func presenting<Presented, PresentedID>(
    state toPresentedState: PresentingReducerToPresentedState<State, Presented.State>,
    id toPresentedId: PresentingReducerToPresentedId<Presented.State, PresentedID>,
    action toPresentedAction: CasePath<Action, Presented.Action>,
    onPresent: PresentingReducerAction<State, Presented.State, Action> = .empty,
    onDismiss: PresentingReducerAction<State, Presented.State, Action> = .empty,
    @ReducerBuilderOf<Presented> presented: () -> Presented,
    file: StaticString = #file,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> _PresentingReducer<Self, Presented, PresentedID>
  where Presented: ReducerProtocol,
        PresentedID: Hashable
  {
    .init(
      reducerId: UUID(),
      parent: self,
      presented: presented(),
      toPresentedState: toPresentedState,
      toPresentedId: toPresentedId,
      toPresentedAction: toPresentedAction,
      onPresent: onPresent,
      onDismiss: onDismiss,
      file: file,
      fileID: fileID,
      line: line
    )
  }
}

public struct _PresentingReducer<Parent, Presented, PresentedID>: ReducerProtocol
where Parent: ReducerProtocol,
      Presented: ReducerProtocol,
      PresentedID: Hashable
{
  @usableFromInline
  let reducerId: UUID

  @usableFromInline
  let parent: Parent

  @usableFromInline
  let presented: Presented

  @usableFromInline
  let toPresentedState: PresentingReducerToPresentedState<Parent.State, Presented.State>

  @usableFromInline
  let toPresentedId: PresentingReducerToPresentedId<Presented.State, PresentedID>

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
    reducerId: UUID,
    parent: Parent,
    presented: Presented,
    toPresentedState: PresentingReducerToPresentedState<Parent.State, Presented.State>,
    toPresentedId: PresentingReducerToPresentedId<Presented.State, PresentedID>,
    toPresentedAction: CasePath<Parent.Action, Presented.Action>,
    onPresent: PresentingReducerAction<Parent.State, Presented.State, Parent.Action>,
    onDismiss: PresentingReducerAction<Parent.State, Presented.State, Parent.Action>,
    file: StaticString,
    fileID: StaticString,
    line: UInt
  ) {
    self.reducerId = reducerId
    self.parent = parent
    self.presented = presented
    self.toPresentedState = toPresentedState
    self.toPresentedId = toPresentedId
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
    let oldPresentedId = toPresentedId(oldPresentedState)

    let presentedEffectsId = PresentingReducerEffectId(
      reducerID: reducerId,
      presentedID: oldPresentedId
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
          .cancellable(id: presentedEffectsId)

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
          .cancellable(id: presentedEffectsId)
      }
    } else {
      presentedEffects = .none
    }

    let effects = parent.reduce(into: &state, action: action)
    let newState = state
    let newPresentedState = toPresentedState(newState)
    let newPresentedId = toPresentedId(newPresentedState)

    var presentationEffects: [Effect<Action, Never>] = []
    if oldPresentedId != newPresentedId {
      if let oldPresentedState = oldPresentedState {
        presentationEffects.append(onDismiss.run(&state, oldPresentedState))
        presentationEffects.append(.cancel(id: presentedEffectsId))
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

public struct PresentingReducerToPresentedId<State, ID: Hashable> {
  public typealias Run = (State?) -> ID

  public static func notNil<State>() -> PresentingReducerToPresentedId<State, Bool> {
    .init { $0 != nil }
  }

  public static func keyPath(_ keyPath: KeyPath<State?, ID>) -> PresentingReducerToPresentedId<State, ID> {
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

public struct PresentingReducerAction<State, ChildState, Action> {
  public typealias Run = (inout State, ChildState) -> Effect<Action, Never>

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
